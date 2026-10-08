// OWNER: ENG-01
//
// iOS + Android implementation of the editor engine contract. Only the app root constructs
// [MobileEditorEngine] (ARCH §4.1).

library;

export 'src/error_mapper.dart' show guardEngineCall, mapEngineError;
export 'src/mobile_editor_engine.dart';
