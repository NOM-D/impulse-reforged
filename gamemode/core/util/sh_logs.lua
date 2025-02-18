LOG_LEVEL_ERROR = 4   --- Only print out errors.
LOG_LEVEL_WARNING = 3 --- Print out warnings and errors.
LOG_LEVEL_INFO = 2    --- Print out info, warnings, and errors.
LOG_LEVEL_DEBUG = 1   --- Print out all log levels.

--- Logging utilities for the gamemode.
-- @module impulse.Logs
impulse.Logs = impulse.Logs or {
    --- The header for all log messages. Typically the name of the gamemode.
    Header = "[impulse-reforged]",
    LogLevel = LOG_LEVEL_DEBUG
}

local MsgC = MsgC
local Color = Color


--- Colors for different log levels.
local clrInfo = Color(125, 173, 250)
local clrError = Color(255, 0, 0)
local clrWarning = Color(255, 255, 0)
local clrSuccess = Color(0, 255, 0)
local clrDatabase = Color(115, 0, 255)
local clrWhite = Color(255, 255, 255)
local clrDebug = Color(150, 150, 150)
local logHeader = impulse.Logs.Header


--- Log an Info-level message. Used for general debug messages.
--- @param fmt string The format string.
--- @param ... any The values to format into the string.
function impulse.Logs:Info(fmt, ...)
    if self.LogLevel > LOG_LEVEL_INFO then return end
    MsgC(clrInfo, logHeader .. " [INFO] ", clrWhite, string.format(fmt, ...), "\n")
end

--- Log a Debug-level message. Used for detailed debug messages.
--- @param fmt string The format string.
--- @param ... any The values to format into the string.
function impulse.Logs:Debug(fmt, ...)
    if self.LogLevel > LOG_LEVEL_DEBUG then return end
    MsgC(clrDebug, logHeader .. " [DEBUG] ", clrWhite, string.format(fmt, ...), "\n")
end

--- Log an Error-level message. Used for critical errors.
--- @param fmt string The format string.
--- @param ... any The values to format into the string.
function impulse.Logs:Error(fmt, ...)
    if self.LogLevel > LOG_LEVEL_ERROR then return end
    local msg = string.format(fmt, ...)
    local trace = debug.traceback("", 2)

    MsgC(clrError, logHeader .. " [ERROR] ", clrWhite, msg)
    MsgC(clrDebug, trace, "\n")
end

--- Log a Warning-level message. Used for non-critical errors.
--- @param fmt string The format string.
--- @param ... any The values to format into the string.
function impulse.Logs:Warning(fmt, ...)
    if self.LogLevel > LOG_LEVEL_WARNING then return end
    MsgC(clrWarning, logHeader .. " [WARNING] ", clrWhite, string.format(fmt, ...), "\n")
end

--- Log a Success-level message. Used for successful operations.
--- @param fmt string The format string.
--- @param ... any The values to format into the string.
function impulse.Logs:Success(fmt, ...)
    if self.LogLevel > LOG_LEVEL_INFO then return end
    MsgC(clrSuccess, logHeader .. " [SUCCESS] ", clrWhite, string.format(fmt, ...), "\n")
end

--- Log a Database-level message. Used for database operations.
--- @param fmt string The format string.
--- @param ... any The values to format into the string.
function impulse.Logs:Database(fmt, ...)
    if self.LogLevel > LOG_LEVEL_INFO then return end
    MsgC(clrDatabase, logHeader .. " [DB] ", clrWhite, string.format(fmt, ...), "\n")
end
