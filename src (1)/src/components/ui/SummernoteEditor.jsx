// import React from "react";
// import "summernote/dist/summernote-lite.css";
// import $ from "jquery";
// import "summernote/dist/summernote-lite.js";

// const SummernoteEditor = ({ value, onChange }) => {
//   const editorRef = React.useRef();

//   React.useEffect(() => {
//     $(editorRef.current).summernote({
//       height: 350,
//       tabsize: 2,
//       callbacks: {
//         onChange: (contents) => {
//           onChange(contents);
//         },
//       },
//     });
//     // Set initial value
//     $(editorRef.current).summernote("code", value || "");
//     return () => {
//       $(editorRef.current).summernote("destroy");
//     };
//     // eslint-disable-next-line
//   }, []);

//   React.useEffect(() => {
//     if ($(editorRef.current).summernote("code") !== value) {
//       $(editorRef.current).summernote("code", value || "");
//     }
//   }, [value]);

//   return <textarea ref={editorRef} />;
// };

// export default SummernoteEditor;

// import React from "react";
// import "summernote/dist/summernote-lite.css";
// import $ from "jquery";
// import "summernote/dist/summernote-lite.js";

// const SummernoteEditor = ({ value, onChange }) => {
//   const editorRef = React.useRef();

//   React.useEffect(() => {
//     $(editorRef.current).summernote({
//       height: 350,
//       tabsize: 2,
//       toolbar: [
//         ["style", ["bold", "italic", "underline", "clear"]],
//         ["para", ["ul", "ol", "paragraph"]],
//         ["insert", ["link", "picture", "video"]],
//         ["view", ["fullscreen", "codeview"]],
//         ["mybuttons", ["h1", "h2", "body"]], // Custom buttons
//       ],

//       buttons: {
//         h1: function () {
//           return $.summernote.ui
//             .button({
//               contents: "<b>Heading</b>",
//               tooltip: "Heading (22px)",
//               click: function () {
//                 document.execCommand("fontSize", false, 7);
//                 $("font[size=7]").removeAttr("size").css("font-size", "22px");
//               },
//             })
//             .render();
//         },

//         h2: function () {
//           return $.summernote.ui
//             .button({
//               contents: "<b>Subtitle</b>",
//               tooltip: "Subtitle (16px)",
//               click: function () {
//                 document.execCommand("fontSize", false, 6);
//                 $("font[size=6]").removeAttr("size").css("font-size", "16px");
//               },
//             })
//             .render();
//         },

//         body: function () {
//           return $.summernote.ui
//             .button({
//               contents: "Body",
//               tooltip: "Body Text (14px)",
//               click: function () {
//                 document.execCommand("fontSize", false, 5);
//                 $("font[size=5]").removeAttr("size").css("font-size", "14px");
//               },
//             })
//             .render();
//         },
//       },

//       callbacks: {
//         onChange: (contents) => {
//           onChange(contents);
//         },
//       },
//     });

//     // initial value
//     $(editorRef.current).summernote("code", value || "");

//     return () => {
//       $(editorRef.current).summernote("destroy");
//     };
//   }, []);

//   // Sync external value
//   React.useEffect(() => {
//     if ($(editorRef.current).summernote("code") !== value) {
//       $(editorRef.current).summernote("code", value || "");
//     }
//   }, [value]);

//   return <textarea ref={editorRef} />;
// };

// export default SummernoteEditor;


import React from "react";
import "summernote/dist/summernote-lite.css";
import $ from "jquery";
import "summernote/dist/summernote-lite.js";

const SummernoteEditor = ({ value, onChange }) => {
  const editorRef = React.useRef();

  React.useEffect(() => {
    $(editorRef.current).summernote({
      height: 350,
      tabsize: 2,
      tooltip: false, // IMPORTANT – disable tooltip everywhere

      toolbar: [
        ["style", ["bold", "italic", "underline", "clear"]],
        ["para", ["ul", "ol", "paragraph"]],
        ["insert", ["link", "picture", "video"]],
        ["view", ["fullscreen", "codeview"]],
        ["mybuttons", ["h1", "h2", "body"]],
      ],

      buttons: {
        h1: function () {
          return $.summernote.ui
            .button({
              contents: "<b>Heading</b>",
              tooltip: false,
              click: function () {
                document.execCommand("fontSize", false, 7);
                $("font[size=7]").removeAttr("size").css("font-size", "22px");
              },
            })
            .render();
        },

        h2: function () {
          return $.summernote.ui
            .button({
              contents: "<b>Subtitle</b>",
              tooltip: false,
              click: function () {
                document.execCommand("fontSize", false, 6);
                $("font[size=6]").removeAttr("size").css("font-size", "16px");
              },
            })
            .render();
        },

        body: function () {
          return $.summernote.ui
            .button({
              contents: "Body",
              tooltip: false,
              click: function () {
                document.execCommand("fontSize", false, 5);
                $("font[size=5]").removeAttr("size").css("font-size", "14px");
              },
            })
            .render();
        },
      },

      callbacks: {
        onChange: (contents) => {
          onChange(contents);
        },
      },
    });

    $(editorRef.current).summernote("code", value || "");

    return () => {
      try {
        $(editorRef.current).summernote("destroy");
      } catch (e) {}
    };
  }, []);

  React.useEffect(() => {
    if ($(editorRef.current).summernote("code") !== value) {
      $(editorRef.current).summernote("code", value || "");
    }
  }, [value]);

  return <textarea ref={editorRef} />;
};

export default SummernoteEditor;
