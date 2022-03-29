fn main() {
    eprintln!(r#"{{"rendered": "I am a fake rustc\nvery very fake"}}"#);
    eprintln!(r#"{{"emit": "metadata"}}"#);
    std::thread::sleep(std::time::Duration::from_secs(1));
    eprintln!(r#"{{"rendered": "I should not print this"}}"#);
}
