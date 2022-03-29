use std::io::{self, prelude::*};
use std::thread;

pub(crate) fn process_output<F>(
    read_end: Box<dyn Read + Send>,
    write_end: Box<dyn Write + Send>,
    mut process_line: F,
) -> thread::JoinHandle<io::Result<()>>
where
    F: FnMut(String) -> Option<String> + Send + 'static,
{
    thread::spawn(move || {
        let mut reader = io::BufReader::new(read_end);
        let mut writer = io::LineWriter::new(write_end);
        loop {
            let mut line = String::new();
            let read_bytes = reader.read_line(&mut line)?;
            if read_bytes == 0 {
                break;
            }
            if let Some(to_write) = process_line(line) {
                writer.write_all(&to_write.into_bytes())?;
            }
        }
        Ok(())
    })
}
