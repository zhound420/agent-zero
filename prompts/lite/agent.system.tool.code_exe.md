### code_execution_tool

Execute terminal commands, Python, or Node.js code.
Args:
- runtime: "terminal" | "python" | "nodejs" | "output" | "reset"
- code: code to execute (escape/indent properly)
- session: session number (0 default, others for multitasking)

Use "output" to wait for long-running code, "reset" to kill stuck process.
Install packages with pip/npm/apt-get in terminal runtime.
Check for placeholders before running - use real variables.
Wait for response before using other tools.

Example:
~~~json
{
    "thoughts": ["Need to check directory"],
    "headline": "Checking current directory",
    "tool_name": "code_execution_tool",
    "tool_args": {
        "runtime": "python",
        "session": 0,
        "code": "import os\nprint(os.getcwd())"
    }
}
~~~
