import React from "react";
import { useParams } from "react-router-dom";
import { TEMPLATE_LIST } from "../../templates";
import NoIndex from "../common/NoIndex";

export default function TemplateCustomizePage() {
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
    if (!Component) return <div className="p-6">Loading…</div>;

    return (
        <div className="">
            <NoIndex />
            <div className="border rounded-md overflow-hidden">
                <Component />
            </div>
            <div className="border rounded-md p-4">
                {/* Placeholder for editor form. Later this can be a dynamic form from schema. */}
                <h2 className="text-xl font-semibold mb-4">Customize</h2>
                <div className="space-y-3">
                    <label className="block">
                        <span className="text-sm">Bride Name</span>
                        <input className="mt-1 w-full border rounded px-2 py-1" placeholder="e.g., Aisha" />
                    </label>
                    <label className="block">
                        <span className="text-sm">Groom Name</span>
                        <input className="mt-1 w-full border rounded px-2 py-1" placeholder="e.g., Rahul" />
                    </label>
                    <label className="block">
                        <span className="text-sm">Date</span>
                        <input type="date" className="mt-1 w-full border rounded px-2 py-1" />
                    </label>
                    <button className="mt-3 px-4 py-2 bg-pink-600 text-white rounded">Save</button>
                </div>
            </div>
        </div>
    );
}


