import {
  useState,
  useCallback,
  useEffect,
  createContext,
  useContext,
} from "react";

const ToastContext = createContext();

export const useToast = () => useContext(ToastContext);

const ToastProvider = ({ children }) => {
  const [toasts, setToasts] = useState([]);

  const addToast = useCallback((message, type = "success") => {
    const id = Date.now();
    setToasts((prev) => [...prev, { id, message, type }]);

    setTimeout(() => {
      setToasts((prev) => prev.filter((toast) => toast.id !== id));
    }, 3000);
  }, []);

  const removeToast = (id) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  };

  return (
    <ToastContext.Provider value={{ addToast }}>
      {children}

      <div
        className="toast-container position-fixed end-0 p-3"
        style={{ top: "85px", zIndex: 1055 }}
      >
        {toasts.map(({ id, message, type }) => {
          const isError = type === "error" || type === "danger";
          const bg = isError ? "#ef4444" : "#ed1173";
          const shadow = isError
            ? "0 8px 24px rgba(239, 68, 68, 0.3)"
            : "0 8px 24px rgba(237, 17, 115, 0.35)";

          return (
            <div
              key={id}
              className="toast show align-items-center text-white border-0 rounded-pill mb-2 px-4 py-2"
              style={{
                backgroundColor: bg,
                boxShadow: shadow,
                border: "1px solid rgba(255, 255, 255, 0.25)",
                minWidth: "240px",
                maxWidth: "420px",
                transition: "all 0.3s ease",
              }}
              role="alert"
              aria-live="assertive"
              aria-atomic="true"
            >
              <div className="d-flex align-items-center justify-content-between w-100 gap-2">
                <div className="d-flex align-items-center gap-2">
                  <span
                    style={{
                      width: "20px",
                      height: "20px",
                      borderRadius: "50%",
                      backgroundColor: "rgba(255, 255, 255, 0.25)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      fontSize: "11px",
                      fontWeight: "bold",
                    }}
                  >
                    {isError ? "✕" : "✓"}
                  </span>
                  <div className="toast-body fw-semibold small p-0 text-white">
                    {message}
                  </div>
                </div>
                <button
                  type="button"
                  className="btn-close btn-close-white ms-2"
                  style={{ opacity: 0.85, width: "0.65rem", height: "0.65rem" }}
                  onClick={() => removeToast(id)}
                ></button>
              </div>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
};

export default ToastProvider;
