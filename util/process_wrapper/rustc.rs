use std::sync::mpsc::SyncSender;
use tinyjson::JsonValue;

#[derive(Debug, Copy, Clone)]
pub(crate) enum Output {
    Json,
    Rendered,
}

impl Default for Output {
    fn default() -> Self {
        Self::Rendered
    }
}

fn get_key(value: JsonValue, key: &str) -> Option<String> {
    if let JsonValue::Object(mut map) = value {
        if let JsonValue::String(s) = map.remove(key)? {
            Some(s)
        } else {
            None
        }
    } else {
        None
    }
}

pub(crate) fn process_message(
    line: String,
    output: Output,
    stop: &SyncSender<()>,
) -> Option<String> {
    let parsed: JsonValue = line
        .parse()
        .expect("process wrapper error: expected json messages in pipeline mode");
    if let Some(emit) = get_key(parsed.clone(), "emit") {
        // We don't want to print emit messages.
        // If the emit messages is "metadata" we can signal the process to quit
        if emit == "metadata" {
            stop.send(())
                .expect("process wrapper error: receiver closed");
        }
        return None;
    };

    match output {
        // If the output should be json, we just forward the messages as-is
        Output::Json => Some(line),
        // Otherwise we extract the "rendered" attribute.
        // If we don't find it we skip the line.
        _ => get_key(parsed, "rendered"),
    }
}
