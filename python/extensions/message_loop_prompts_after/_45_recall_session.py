from python.helpers.extension import Extension
from python.helpers.memory import Memory
from python.helpers import settings
from agent import LoopData


class RecallSession(Extension):
    """
    Recalls session state on first message or when user explicitly asks to continue.
    This enables seamless continuation across sessions for small context models.
    """

    async def execute(self, loop_data: LoopData = LoopData(), **kwargs):
        set = settings.get_settings()

        # Only run if session continuation is enabled
        if not set.get("session_continuation_enabled", False):
            return

        # Check if this is the first message in the session
        is_first_message = self.agent.history.counter <= 1

        # Check if user is explicitly asking to continue
        user_msg = ""
        if loop_data.user_message:
            user_msg = str(loop_data.user_message.output_text() if hasattr(loop_data.user_message, 'output_text') else loop_data.user_message).lower()

        continuation_keywords = [
            "continue",
            "resume",
            "where were we",
            "pick up",
            "last session",
            "previous session",
            "carry on",
        ]
        wants_continue = any(kw in user_msg for kw in continuation_keywords)

        # Only recall on first message OR explicit continuation request
        if not is_first_message and not wants_continue:
            return

        # Don't recall if we already have session state in this loop
        if "session_state" in loop_data.extras_persistent:
            return

        try:
            db = await Memory.get(self.agent)

            # Search for session state
            states = await db.search_similarity_threshold(
                query="session state continuation current task goal next steps context",
                limit=1,
                threshold=0.5,
                filter="area=='session_state'",
            )

            if states:
                state_content = states[0].page_content

                # Inject into extras for prompt inclusion
                loop_data.extras_persistent["session_state"] = f"""
## Previous Session Context

The following is your saved state from a previous session. Use this to continue seamlessly:

{state_content}

---
Note: This state was recalled automatically. Verify any time-sensitive information before proceeding.
"""

                self.agent.context.log.log(
                    type="util",
                    heading="Session state recalled",
                    content=state_content[:300] + "..." if len(state_content) > 300 else state_content,
                )

        except Exception as e:
            self.agent.context.log.log(
                type="warning",
                heading=f"Could not recall session state: {str(e)}",
            )
