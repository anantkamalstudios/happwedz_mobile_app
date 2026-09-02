import { createTheme } from "@mui/material/styles";

const muiTheme = createTheme({
  typography: {
    fontFamily: "var(--rubik-font)",
    allVariants: {
      fontFamily: "var(--rubik-font)",
    },
  },
  components: {
    MuiCssBaseline: {
      styleOverrides: {
        "*": {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiTypography: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiInputBase: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiInputLabel: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiSelect: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiMenuItem: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiCheckbox: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiRadio: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiFormControlLabel: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiTab: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiDialog: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiDialogTitle: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiDialogContent: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiDatePicker: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiPickersDay: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
    MuiPickersCalendarHeader: {
      styleOverrides: {
        root: {
          fontFamily: "var(--rubik-font)",
        },
      },
    },
  },
});

export default muiTheme;
