function Mqrb() { }
(function () {
  var USE_WASM = /[ \(]iP/.test(navigator.userAgent) ? false : true; // Not use webassembly if IOS

  var el_corescript = document.createElement("script");
  var runtimePath = "mqrb/wasm/mqrb-core.js";
  var module;
  var moduleArgs = {
    onRuntimeInitialized: function () {
      module.cwrap('mqrb_initialize', 'number')()
      Mqrb.createInstance = module.cwrap('mqrb_create_instance', 'number');
      Mqrb.execIrep = module.cwrap('mqrb_exec_irep', null, ['number', 'array']);
      Mqrb.execScript = module.cwrap('mqrb_exec_script', null, ['number', 'string']);
      Mqrb.onRuntimeInitialized();
    }
  }

  if (USE_WASM)
  {
    el_corescript.src = runtimePath;
    el_corescript.addEventListener("load", function () {
      fetch('mqrb/wasm/mqrb-core.wasm')
        .then(response => response.arrayBuffer())
        .then(buffer => new Uint8Array(buffer))
        .then(binary => {
          moduleArgs.wasmBinary = binary;
          module = Module(moduleArgs);
        });
    });
  }
  else {
    console.log('[MQRB] No use wasm.')
    el_corescript.src = "mqrb/asm/mqrb-core.js";
    el_corescript.addEventListener("load", function () {
      module = Module(moduleArgs);
    });
  }

  document.head.appendChild(el_corescript);
}());
