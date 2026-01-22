/**
 * Structured Logger Service
 *
 * Outputs JSON logs with consistent format:
 * { timestamp, level, requestId, message, ...extra }
 *
 * Features:
 * - JSON format for machine parsing
 * - Slack alerts for critical events (alert: true in logs)
 * - Request context tracking
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  requestId?: string;
  message: string;
  alert?: boolean; // If true, send to Slack
  [key: string]: unknown; // Extra fields (userId, merchantId, etc.)
}

// Should we output logs? (disable in tests)
const isEnabled = Bun.env.NODE_ENV !== 'test';

// In production, skip debug logs
const minLevel: LogLevel = Bun.env.NODE_ENV === 'production' ? 'info' : 'debug';

// Slack webhook URL for alerts
const SLACK_WEBHOOK_URL = Bun.env.SLACK_WEBHOOK_URL;
const SLACK_ENABLED = !!SLACK_WEBHOOK_URL && Bun.env.NODE_ENV !== 'test';

const levelPriority: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

function shouldLog(level: LogLevel): boolean {
  return isEnabled && levelPriority[level] >= levelPriority[minLevel];
}

function formatLog(level: LogLevel, message: string, extra?: Record<string, unknown>): LogEntry {
  return {
    timestamp: new Date().toISOString(),
    level,
    message,
    ...extra,
  };
}

function output(entry: LogEntry) {
  // In development, pretty print; in production, single line JSON
  if (Bun.env.NODE_ENV === 'development') {
    const { level, message, alert, ...rest } = entry;
    const prefix =
      level === 'error' ? '❌' : level === 'warn' ? '⚠️' : level === 'info' ? '✅' : '🔍';
    const alertStr = alert ? ' 🚨 [ALERT]' : '';
    console.log(
      `${prefix} [${level.toUpperCase()}]${alertStr} ${message}`,
      Object.keys(rest).length > 1 ? rest : ''
    );
  } else {
    console.log(JSON.stringify(entry));
  }
}

/**
 * Send alert to Slack webhook
 * Only sends if alert flag is true and webhook is configured
 */
async function sendSlackAlert(entry: LogEntry): Promise<void> {
  if (!SLACK_ENABLED || !entry.alert) return;
  if (entry.level === 'debug') return; // Skip debug alerts

  try {
    const emoji = entry.level === 'error' ? '❌' : entry.level === 'warn' ? '⚠️' : 'ℹ️';
    const color = entry.level === 'error' ? 'danger' : entry.level === 'warn' ? 'warning' : 'good';

    // Format extra fields for display
    const { timestamp, level, message, alert, ...fields } = entry;
    const fieldsList = Object.entries(fields)
      .map(([k, v]) => ({
        title: k,
        value: typeof v === 'string' ? v : JSON.stringify(v),
        short: true,
      }))
      .slice(0, 10); // Limit to 10 fields for readability

    const payload = {
      text: `${emoji} [${level.toUpperCase()}] ${message}`,
      attachments: [
        {
          fallback: message,
          color,
          title: message,
          fields: fieldsList,
          footer: 'Druto System',
          ts: Math.floor(new Date(timestamp).getTime() / 1000),
        },
      ],
    };

    const response = await fetch(SLACK_WEBHOOK_URL!, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      console.error(`Slack alert failed: ${response.status} ${response.statusText}`);
    }
  } catch (err) {
    // Don't throw - logging errors should never crash the app
    console.error('Error sending Slack alert:', err);
  }
}

/**
 * Logger with optional request context
 *
 * Usage:
 *   logger.info('User created', { userId: '123' });
 *   logger.error('Payment failed', { merchantId, error: err.message });
 *
 * Slack alerts:
 *   logger.warn('Subscription issue', { alert: true, merchantId }); // Sends to Slack
 *
 * With request context:
 *   const log = logger.withRequest(requestId);
 *   log.info('Request started');
 */
export const logger = {
  debug(message: string, extra?: Record<string, unknown>) {
    if (shouldLog('debug')) output(formatLog('debug', message, extra));
  },

  info(message: string, extra?: Record<string, unknown>) {
    if (shouldLog('info')) {
      const entry = formatLog('info', message, extra);
      output(entry);
      sendSlackAlert(entry); // Send to Slack if flagged
    }
  },

  warn(message: string, extra?: Record<string, unknown>) {
    if (shouldLog('warn')) {
      const entry = formatLog('warn', message, extra);
      output(entry);
      sendSlackAlert(entry); // Send to Slack if flagged
    }
  },

  error(
    message: string,
    errorOrExtra?: Error | Record<string, unknown>,
    extra?: Record<string, unknown>
  ) {
    if (!shouldLog('error')) return;

    // Support both: logger.error('msg', { extra }) and logger.error('msg', err, { extra })
    let logExtra: Record<string, unknown> = {};

    if (errorOrExtra instanceof Error) {
      logExtra = {
        errorName: errorOrExtra.name,
        errorMessage: errorOrExtra.message,
        stack: errorOrExtra.stack,
        ...extra,
      };
    } else if (errorOrExtra) {
      logExtra = errorOrExtra;
    }

    const entry = formatLog('error', message, logExtra);
    output(entry);
    sendSlackAlert(entry); // Always send errors to Slack
  },

  // Create a logger instance bound to a specific request
  withRequest(requestId: string) {
    return {
      debug: (msg: string, extra?: Record<string, unknown>) =>
        logger.debug(msg, { requestId, ...extra }),
      info: (msg: string, extra?: Record<string, unknown>) =>
        logger.info(msg, { requestId, ...extra }),
      warn: (msg: string, extra?: Record<string, unknown>) =>
        logger.warn(msg, { requestId, ...extra }),
      error: (
        msg: string,
        errorOrExtra?: Error | Record<string, unknown>,
        extra?: Record<string, unknown>
      ) => logger.error(msg, errorOrExtra, { requestId, ...extra }),
    };
  },
};
