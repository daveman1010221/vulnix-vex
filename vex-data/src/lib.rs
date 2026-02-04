use serde::{Serialize, Deserialize};
use ts_rs::TS;

#[derive(Debug, Clone, Serialize, Deserialize, TS)]
#[ts(export)]
pub struct VexEntry {
    pub id: u32,
    pub description: String,
    pub severity: String,
    pub affected_package: String,
    pub justification: String,
    pub status: String,
    pub impact_statement: String,
    pub action_statement: String,
}
