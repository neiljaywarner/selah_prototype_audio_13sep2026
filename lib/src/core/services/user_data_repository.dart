/// Local favorites live on UserPreferences as My passages
/// (preference key `selah.my_passages`).
///
/// This file used to hold an unused in-memory set (PSA.23, COL.1) that
/// nothing in the app read. That second store is gone so bookmark, reload,
/// and replay share one list. A future account sync should read and write
/// UserPreferences, not a parallel favorites collection.
library;
