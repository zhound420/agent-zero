## Task Scheduler

Execute tasks by schedule (cron), plan (datetime list), or manually (adhoc).
Tasks run in background. Use scheduler:wait_for_task to get results.

### Task Types
- **scheduled**: Recurring cron schedule (5 fields: minute hour day month weekday)
- **planned**: Fixed datetime list (ISO format: %Y-%m-%dT%H:%M:%S)
- **adhoc**: Manual execution only

### Tools

**scheduler:list_tasks** - List tasks with filters
Args: state (list), type (list), next_run_within (int), next_run_after (int)

**scheduler:find_task_by_name** - Find by name
Args: name (str)

**scheduler:show_task** - Show task details
Args: uuid (str)

**scheduler:run_task** - Execute task manually
Args: uuid (str), context (str, optional)

**scheduler:delete_task** - Remove task
Args: uuid (str)

**scheduler:create_scheduled_task** - Create cron task
Args: name, system_prompt, prompt, schedule (dict with minute/hour/day/month/weekday), attachments (list), dedicated_context (bool)

**scheduler:create_planned_task** - Create datetime-scheduled task
Args: name, system_prompt, prompt, plan (list of ISO datetimes), attachments, dedicated_context

**scheduler:create_adhoc_task** - Create manual task
Args: name, system_prompt, prompt, attachments, dedicated_context

**scheduler:wait_for_task** - Wait for task completion (dedicated_context tasks only)
Args: uuid (str)

### Rules
- Don't create duplicate tasks - check existing first
- Tasks scheduled/planned run automatically - don't run manually
- dedicated_context=true for independent execution
