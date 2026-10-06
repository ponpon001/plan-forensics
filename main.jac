"""Plan Forensics web entry point."""

import from .frontend { app as ClientApp }

def:pub app -> JsxElement {
    <ClientApp/>
}
