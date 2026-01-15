from typing import Any
from python.helpers.extension import Extension
from python.helpers.mcp_handler import MCPConfig
from agent import Agent, LoopData
from python.helpers.settings import get_settings
from python.helpers import projects, files


class SystemPrompt(Extension):

    async def execute(
        self,
        system_prompt: list[str] = [],
        loop_data: LoopData = LoopData(),
        **kwargs: Any
    ):
        # append main system prompt and tools
        main = get_main_prompt(self.agent)
        tools = get_tools_prompt(self.agent)
        mcp_tools = get_mcp_tools_prompt(self.agent)
        secrets_prompt = get_secrets_prompt(self.agent)
        project_prompt = get_project_prompt(self.agent)

        system_prompt.append(main)
        system_prompt.append(tools)
        if mcp_tools:
            system_prompt.append(mcp_tools)
        if secrets_prompt:
            system_prompt.append(secrets_prompt)
        if project_prompt:
            system_prompt.append(project_prompt)


def _get_prompt_dirs(agent: Agent) -> list[str]:
    """Get prompt directories, with lite prompts first if small_context_mode is enabled."""
    settings = get_settings()
    dirs = []

    # If small_context_mode, prioritize lite prompts
    if settings.get("small_context_mode", False):
        dirs.append(files.get_abs_path("prompts", "lite"))

    # Agent-specific prompts (if agent has custom profile)
    if agent.config.profile:
        dirs.append(files.get_abs_path("agents", agent.config.profile, "prompts"))

    # Default prompts as fallback
    dirs.append(files.get_abs_path("prompts"))

    return dirs


def get_main_prompt(agent: Agent):
    dirs = _get_prompt_dirs(agent)
    prompt = files.read_prompt_file("agent.system.main.md", _directories=dirs)
    return files.remove_code_fences(prompt)


def get_tools_prompt(agent: Agent):
    dirs = _get_prompt_dirs(agent)
    prompt = files.read_prompt_file("agent.system.tools.md", _directories=dirs)
    prompt = files.remove_code_fences(prompt)
    if agent.config.chat_model.vision:
        vision_prompt = files.read_prompt_file("agent.system.tools_vision.md", _directories=dirs)
        prompt += "\n\n" + files.remove_code_fences(vision_prompt)
    return prompt


def get_mcp_tools_prompt(agent: Agent):
    mcp_config = MCPConfig.get_instance()
    if mcp_config.servers:
        pre_progress = agent.context.log.progress
        agent.context.log.set_progress(
            "Collecting MCP tools"
        )  # MCP might be initializing, better inform via progress bar
        tools = MCPConfig.get_instance().get_tools_prompt()
        agent.context.log.set_progress(pre_progress)  # return original progress
        return tools
    return ""


def get_secrets_prompt(agent: Agent):
    try:
        # Use lazy import to avoid circular dependencies
        from python.helpers.secrets import get_secrets_manager

        secrets_manager = get_secrets_manager(agent.context)
        secrets = secrets_manager.get_secrets_for_prompt()
        vars = get_settings()["variables"]
        return agent.read_prompt("agent.system.secrets.md", secrets=secrets, vars=vars)
    except Exception as e:
        # If secrets module is not available or has issues, return empty string
        return ""


def get_project_prompt(agent: Agent):
    result = agent.read_prompt("agent.system.projects.main.md")
    project_name = agent.context.get_data(projects.CONTEXT_DATA_KEY_PROJECT)
    if project_name:
        project_vars = projects.build_system_prompt_vars(project_name)
        result += "\n\n" + agent.read_prompt(
            "agent.system.projects.active.md", **project_vars
        )
    else:
        result += "\n\n" + agent.read_prompt("agent.system.projects.inactive.md")
    return result
