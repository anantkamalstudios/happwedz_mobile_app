import React from "react";
import { useParams } from "react-router-dom";
import { TEMPLATE_LIST } from "../../templates";
import NoIndex from "../common/NoIndex";

export default function TemplatePreviewPage() {
    const { id } = useParams();
    const tpl = TEMPLATE_LIST.find(t => t.id === id);

    const [Component, setComponent] = React.useState(null);
    const [error, setError] = React.useState("");

    React.useEffect(() => {
        let isMounted = true;
        if (!tpl) {
            setError("Template not found");
            return;
        }
        tpl.load()
            .then(mod => { if (isMounted) setComponent(() => mod.default); })
            .catch(err => { if (isMounted) setError(err?.message || "Failed to load template"); });
        return () => { isMounted = false; };
    }, [tpl]);

    if (!tpl) return <div className="p-6">Template not found.</div>;
    if (error) return <div className="p-6 text-red-600">{error}</div>;
    if (!Component) return <div className="p-6">Loading preview…</div>;

    return (
        <div className="min-h-screen bg-white">
            <NoIndex />
            <Component />
        </div>
    );
}


