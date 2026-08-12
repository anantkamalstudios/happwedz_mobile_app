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
        className="toast-container position-fixed top-0 end-0 p-3"
        style={{ zIndex: 1055 }}
      >
        {toasts.map(({ id, message, type }) => (
          <div
            key={id}
            className={`toast show align-items-center text-white bg-${type} border-0 rounded-pill shadow-sm mb-2 px-4 py-2`}
            role="alert"
            aria-live="assertive"
            aria-atomic="true"
          >
            <div className="d-flex align-items-center justify-content-between w-100">
              <div className="toast-body fw-semibold small">{message}</div>
              <button
                type="button"
                className="btn-close btn-close-white ms-3"
                onClick={() => removeToast(id)}
              ></button>
            </div>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
};

export default ToastProvider;
