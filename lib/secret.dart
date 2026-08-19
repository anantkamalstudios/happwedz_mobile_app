// AUDIT NOTE:
// This file held a live Google/Gemini API key committed in plain text, and
// nothing in `lib/` ever imported it — it was dead code that leaked a
// credential to anyone with access to the repository.
// Kept intentionally and commented out as requested.
// Do not remove without confirming with the project owner.
//
// ⚠️ ACTION REQUIRED BY THE PROJECT OWNER: the key below was exposed in source
// control, so commenting it out does NOT make it safe. Revoke/rotate it in the
// Google Cloud console. If a Gemini key is needed again, pass it in at build
// time (`--dart-define=GEMINI_API_KEY=…`) and read it with
// `String.fromEnvironment`, so no secret is ever committed.
//
// const String geminiApiKey = 'AIzaSyCWjpUUScvL0rl4Jj_t_4VvMCudA6oy6ws';