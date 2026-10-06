"""Shared native design tokens for the Plan Forensics mobile client."""
import from "@jac/mobui" { StyleSheet }

obj MobileColors {
    has paper: str = "#f7f7f5",
        surface: str = "#ffffff",
        ink: str = "#202020",
        muted: str = "#787774",
        line: str = "#e2e2df",
        violet: str = "#6c5ce7",
        violetSoft: str = "#efedff",
        green: str = "#3f8f65",
        greenSoft: str = "#e7f4ec",
        red: str = "#d65a53";
}

glob:pub MC = MobileColors(),
     MS = StyleSheet.create(
         {
             "screen": {"flex": 1, "backgroundColor": MC.paper},
             "page": {
                 "width": "100%",
                 "maxWidth": 720,
                 "alignSelf": "center",
                 "padding": 20,
                 "gap": 18
             },
             "header": {
                 "flexDirection": "row",
                 "justifyContent": "space-between",
                 "alignItems": "center",
                 "paddingVertical": 6
             },
             "brandRow": {"flexDirection": "row", "alignItems": "center", "gap": 10},
             "brandMark": {
                 "width": 34,
                 "height": 34,
                 "borderRadius": 9,
                 "backgroundColor": MC.ink,
                 "justifyContent": "center",
                 "alignItems": "center"
             },
             "brandMarkText": {
                 "color": "#ffffff",
                 "fontSize": 10,
                 "fontWeight": "800",
                 "letterSpacing": 1
             },
             "brand": {"color": MC.ink, "fontSize": 16, "fontWeight": "700"},
             "eyebrow": {
                 "color": MC.muted,
                 "fontSize": 10,
                 "fontWeight": "700",
                 "letterSpacing": 1.5
             },
             "title": {
                 "color": MC.ink,
                 "fontSize": 34,
                 "lineHeight": 38,
                 "fontWeight": "700",
                 "letterSpacing": -1.5
             },
             "subtitle": {"color": MC.muted, "fontSize": 14, "lineHeight": 21},
             "card": {
                 "backgroundColor": MC.surface,
                 "borderWidth": 1,
                 "borderColor": MC.line,
                 "borderRadius": 14,
                 "padding": 16,
                 "gap": 12
             },
             "taskCard": {
                 "backgroundColor": MC.surface,
                 "borderWidth": 1,
                 "borderColor": MC.line,
                 "borderRadius": 12,
                 "padding": 14,
                 "gap": 9
             },
             "row": {"flexDirection": "row", "alignItems": "center", "gap": 10},
             "between": {
                 "flexDirection": "row",
                 "alignItems": "center",
                 "justifyContent": "space-between",
                 "gap": 10
             },
             "stack": {"gap": 12},
             "input": {
                 "borderWidth": 1,
                 "borderColor": MC.line,
                 "borderRadius": 9,
                 "paddingHorizontal": 12,
                 "paddingVertical": 11,
                 "fontSize": 15,
                 "color": MC.ink,
                 "backgroundColor": "#ffffff"
             },
             "button": {
                 "backgroundColor": MC.ink,
                 "paddingHorizontal": 16,
                 "paddingVertical": 11,
                 "borderRadius": 9,
                 "alignItems": "center"
             },
             "buttonText": {"color": "#ffffff", "fontSize": 13, "fontWeight": "700"},
             "quietButton": {"backgroundColor": "#eeeeeb"},
             "quietButtonText": {"color": MC.ink},
             "taskTitle": {
                 "color": MC.ink,
                 "fontSize": 15,
                 "fontWeight": "600",
                 "lineHeight": 21
             },
             "meta": {"color": MC.muted, "fontSize": 11},
             "pill": {
                 "backgroundColor": MC.violetSoft,
                 "paddingHorizontal": 7,
                 "paddingVertical": 4,
                 "borderRadius": 999
             },
             "pillText": {
                 "color": MC.violet,
                 "fontSize": 9,
                 "fontWeight": "700",
                 "textTransform": "uppercase"
             },
             "check": {
                 "width": 30,
                 "height": 30,
                 "borderRadius": 9,
                 "borderWidth": 1,
                 "borderColor": MC.line,
                 "justifyContent": "center",
                 "alignItems": "center"
             },
             "checkDone": {"backgroundColor": MC.green, "borderColor": MC.green},
             "checkText": {"color": "#ffffff", "fontWeight": "800"},
             "summary": {
                 "backgroundColor": MC.violetSoft,
                 "borderRadius": 12,
                 "padding": 14,
                 "flexDirection": "row",
                 "justifyContent": "space-between",
                 "gap": 12
             },
             "summaryNumber": {"color": MC.violet, "fontSize": 22, "fontWeight": "700"},
             "error": {
                 "padding": 12,
                 "borderRadius": 9,
                 "backgroundColor": "#fbeceb",
                 "color": "#963e39",
                 "fontSize": 12
             },
             "empty": {"paddingVertical": 38, "alignItems": "center", "gap": 8},
             "divider": {"height": 1, "backgroundColor": MC.line},
              "small": {"color": MC.muted, "fontSize": 11, "lineHeight": 17},
              "tabs": {"flexDirection": "row", "gap": 7, "flexWrap": "wrap"},
              "tab": {"paddingHorizontal": 11, "paddingVertical": 9, "borderRadius": 8, "backgroundColor": "#eeeeeb"},
              "tabActive": {"backgroundColor": MC.ink},
              "tabText": {"fontSize": 11, "fontWeight": "700", "color": MC.ink},
              "tabTextActive": {"color": "#ffffff"},
              "label": {"color": MC.muted, "fontSize": 10, "fontWeight": "700", "letterSpacing": 0.7},
              "chipRow": {"flexDirection": "row", "gap": 7, "flexWrap": "wrap"},
              "chip": {"paddingHorizontal": 10, "paddingVertical": 7, "borderRadius": 7, "backgroundColor": "#eeeeeb"},
              "chipActive": {"backgroundColor": MC.violetSoft},
              "chipText": {"color": MC.ink, "fontSize": 11},
              "chipTextActive": {"color": MC.violet, "fontWeight": "700"},
              "focusRow": {"flexDirection": "row", "justifyContent": "space-between", "alignItems": "center", "gap": 9},
              "focusClock": {"fontSize": 20, "fontWeight": "700", "color": MC.ink},
              "recovery": {"padding": 13, "borderRadius": 9, "backgroundColor": MC.greenSoft, "gap": 5},
              "recoveryText": {"color": "#27573c", "fontSize": 14, "lineHeight": 21, "fontWeight": "600"}
         }
     );
