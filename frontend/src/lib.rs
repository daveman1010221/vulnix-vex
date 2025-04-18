use sycamore::prelude::*;

/// Your main frontend app.
#[component]
pub fn App() -> View {
    view! {
        div {
            h1 { "Hello from Vulnix VEX" }
        }
    }
}

#[wasm_bindgen::prelude::wasm_bindgen(start)]
pub fn start() {
    web_sys::console::log_1(&"Starting app...".into());
    sycamore::render(|| view! { App() });
}

#[cfg(test)]
mod tests {
    use super::*;
    use sycamore::render_to_string;

    #[test]
    fn app_renders_hello_world() {
        let rendered = render_to_string(|| view! { App() });
        assert!(rendered.contains("Hello from Vulnix VEX"));
    }
}
