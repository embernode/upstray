use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new_qml_module(
        QmlModule::new("com.upstray.app")
            .qml_file("qml/main.qml")
            .qml_file("qml/Theme.qml")
            .qml_file("qml/components/ChargeRing.qml")
            .qml_file("qml/components/Hero.qml")
            .qml_file("qml/components/FlowArrow.qml")
            .qml_file("qml/components/FlowCell.qml")
            .qml_file("qml/components/StatCard.qml")
            .qml_file("qml/components/MonitorTab.qml")
            .qml_file("qml/components/DetailsTab.qml")
            .qml_file("qml/components/SettingsTab.qml"),
    )
    .qrc_resources([
        "resources/icons/upstray-online.svg",
        "resources/icons/upstray-onbattery.svg",
        "resources/icons/upstray-lowbattery.svg",
        "resources/icons/upstray-disconnected.svg",
    ])
    .qt_module("Network")
    .qt_module("Widgets") // Needed for QApplication
    .files(["src/backend.rs"])
    .cpp_file("cpp/app.cpp")
    .build();

    // Now manually compile the main.rs cxx::bridge since cxx-qt only compiles cxx_qt::bridges automatically
    cxx_build::bridge("src/main.rs")
        // We do NOT add .file("cpp/app.cpp") here because cxx-qt-build already compiles it with Qt paths
        .compile("upstray-app-bridge");

    println!("cargo:rerun-if-changed=src/main.rs");
    println!("cargo:rerun-if-changed=cpp/app.cpp");
    println!("cargo:rerun-if-changed=cpp/app.h");
}
