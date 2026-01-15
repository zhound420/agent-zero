import asyncio
from python.helpers import settings
from python.helpers.extension import Extension
from python.helpers.memory import Memory
from agent import LoopData
from python.helpers.log import LogItem


class SaveSessionState(Extension):
    """
    Saves a condensed session state to memory periodically.
    This enables seamless continuation across sessions for small context models.
    """

    async def execute(self, loop_data: LoopData = LoopData(), **kwargs):
        set = settings.get_settings()

        # Only run if session continuation is enabled
        if not set.get("session_continuation_enabled", False):
            return

        # Save every N messages (based on interval setting)
        interval = set.get("session_save_interval", 3)
        if self.agent.history.counter % interval != 0:
            return

        # Skip if history is too short
        if self.agent.history.counter < 2:
            return

        log_item = self.agent.context.log.log(
            type="util",
            heading="Saving session state for continuation...",
        )

        # Save in background
        task = asyncio.create_task(self._save_state(set, log_item))
        return task

    async def _save_state(self, set: dict, log_item: LogItem):
        try:
            db = await Memory.get(self.agent)

            # Get recent history text
            history_text = self.agent.history.output_text()
            max_chars = set.get("session_state_max_chars", 6000)
            history_text = history_text[-max_chars:]

            if len(history_text) < 100:
                log_item.update(heading="Session too short to save state.")
                return

            # Use utility model to extract key state
            state = await self.agent.call_utility_model(
                system="""Extract session state for continuation. Be concise - this will be injected into limited context.

Include:
1. Current task/goal being worked on
2. Key decisions made
3. Important context (files modified, variables, errors encountered)
4. Next planned steps

Format as a brief, structured summary.""",
                message=f"Conversation to extract state from:\n\n{history_text}",
                background=True,
            )

            if not state or len(state) < 30:
                log_item.update(heading="No significant session state to save.")
                return

            # Delete previous session state (replace with new)
            await db.delete_documents_by_query(
                query="session state continuation context",
                threshold=0.8,
                filter="area=='session_state'",
            )

            # Save new session state
            state_text = f"""# Session State
Context ID: {self.agent.context.id}
Message count: {self.agent.history.counter}

{state}

---
Say "continue" or "resume" in a new session to recall this state."""

            await db.insert_text(
                text=state_text,
                metadata={
                    "area": "session_state",
                    "context_id": self.agent.context.id,
                    "message_count": self.agent.history.counter,
                },
            )

            log_item.update(
                heading="Session state saved.",
                content=state[:200] + "..." if len(state) > 200 else state,
            )

        except Exception as e:
            log_item.update(heading=f"Error saving session state: {str(e)}")
