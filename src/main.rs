pub mod backend;
pub mod config;
pub mod notifier;
pub mod poller;
pub mod ups_state;

#[cxx::bridge]
mod ffi {
    unsafe extern "C++" {
        include!("upstray/cpp/app.h");
        fn run_qapplication();
    }
}

fn main() {
    tracing_subscriber::fmt::init();
    tracing::info!("Starting UpsTray");

    let config = config::load_config();
    let host = config.server.host;
    let port = config.server.port;
    let ups_name = config.server.ups_name;
    let poll_interval = tokio::time::Duration::from_secs(config.general.poll_interval_secs);

    let (state_tx, state_rx) = tokio::sync::watch::channel(ups_state::UpsState::default());
    backend::STATE_RX
        .set(std::sync::Mutex::new(state_rx))
        .expect("Failed to set STATE_RX");

    let (config_tx, config_rx) = tokio::sync::watch::channel((host, port, ups_name));
    backend::CONFIG_TX
        .set(config_tx)
        .expect("Failed to set CONFIG_TX");

    // Spawn background tokio runtime on a new thread since QApplication handles the main thread
    std::thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_multi_thread()
            .enable_time()
            .enable_io()
            .build()
            .expect("Failed to create tokio runtime");

        rt.block_on(async {
            poller::run_polling_loop(state_tx, config_rx, poll_interval).await;
        });
    });

    // Start the app using our C++ wrapper which initializes QApplication instead of QGuiApplication
    ffi::run_qapplication();
}
