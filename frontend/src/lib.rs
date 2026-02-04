use sycamore::prelude::*;
use wasm_bindgen::prelude::*;
use vex_data::VexEntry;

#[component]
pub fn App() -> View {
    let description = create_signal(String::new());
    let severity = create_signal(String::new());
    let affected_package = create_signal(String::new());
    let justification = create_signal(String::new());
    let status = create_signal(String::new());
    let impact_statement = create_signal(String::new());
    let action_statement = create_signal(String::new());

    view! {
        div(class="max-w-xl mx-auto mt-8 p-4 border rounded shadow space-y-4") {
            h1(class="text-2xl font-bold mb-4") { "foobor VEX Entry Form" }
    
            form(class="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto bg-white p-8 rounded-lg shadow-md") {
                div {
                    label(class="space-y-2") { "Description" }
                    input(bind:value=description.clone(), class="w-full border rounded px-4 py-2 text-base", placeholder="e.g. Buffer overflow in XYZ")
                }
    
                div {
                    label(class="space-y-2") { "Severity" }
                    select(bind:value=severity.clone(), class="w-full border rounded px-4 py-2 text-base") {
                        option { "-- Select Severity --" }
                        option { "None" }
                        option { "Low" }
                        option { "Medium" }
                        option { "High" }
                        option { "Critical" }
                    }
                }
    
                div {
                    label(class="space-y-2") { "Package" }
                    input(bind:value=affected_package.clone(), class="w-full border rounded px-4 py-2 text-base", placeholder="e.g. libssl 1.1.1")
                }
    
                div {
                    label(class="space-y-2") { "Justification" }
                    select(bind:value=justification.clone(), class="w-full border rounded px-4 py-2 text-base") {
                        option { "-- Select Justification --" }
                        option { "Component not present" }
                        option { "Vulnerability not applicable" }
                        option { "Mitigated" }
                        option { "No fix available" }
                    }
                }
    
                div {
                    label(class="space-y-2") { "Status" }
                    select(bind:value=status.clone(), class="w-full border rounded px-4 py-2 text-base") {
                        option { "-- Select Status --" }
                        option { "Affected" }
                        option { "Not Affected" }
                        option { "Fixed" }
                    }
                }
    
                div {
                    label(class="space-y-2") { "Impact Statement" }
                    input(bind:value=impact_statement.clone(), class="w-full border rounded px-4 py-2 text-base", placeholder="e.g. Exploitable only if XYZ is enabled")
                }
    
                div {
                    label(class="space-y-2") { "Action Statement" }
                    input(bind:value=action_statement.clone(), class="w-full border rounded px-4 py-2 text-base", placeholder="e.g. Patch available in 1.2.3")
                }
    
                div(class="md:col-span-2 text-center mt-6") {
                    button(on:click=move |_| {
                        let entry = VexEntry {
                            id: 1,
                            description: description.get_clone().to_string(),
                            severity: severity.get_clone().to_string(),
                            affected_package: affected_package.get_clone().to_string(),
                            justification: justification.get_clone().to_string(),
                            status: status.get_clone().to_string(),
                            impact_statement: impact_statement.get_clone().to_string(),
                            action_statement: action_statement.get_clone().to_string(),
                        };
                        web_sys::console::log_1(&format!("{:?}", entry).into());
                    }, class="mt-4 bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700") {
                        "Log Entry"
                    }
                }
            }
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
    fn app_renders_entry_form() {
        let rendered = render_to_string(|| view! { App() });
        assert!(rendered.contains("VEX Entry Form"));
    }
}
