import { useState } from 'react';
import { Share2, Mail, Eye, Check } from 'lucide-react';
import { FaWhatsapp } from 'react-icons/fa';

/**
 * "Share By" row above the results — hands the current search to WhatsApp or
 * email, or copies the link. Everything is built from the page URL, so a
 * recipient lands on the same search rather than a snapshot that goes stale.
 */
export default function ShareBy({ searchParams, resultCount = 0 }) {
  const [copied, setCopied] = useState(false);

  const from = searchParams?.from || '';
  const to = searchParams?.to || '';
  const date = searchParams?.departureDate || '';
  const url = typeof window !== 'undefined' ? window.location.href : '';

  const summary =
    `Flights ${from} → ${to}${date ? ` on ${date}` : ''}` +
    (resultCount ? ` — ${resultCount} option${resultCount > 1 ? 's' : ''}` : '');

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(`${summary}\n${url}`);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      // Clipboard is blocked outside a secure context — leave the icon as-is
      // rather than showing a success state that did not happen.
      setCopied(false);
    }
  };

  return (
    <div className="fc-shareby">
      <Share2 size={13} />
      <span className="fc-shareby-label">Share By :</span>
      <a
        className="fc-shareby-btn"
        href={`https://wa.me/?text=${encodeURIComponent(`${summary}\n${url}`)}`}
        target="_blank"
        rel="noopener noreferrer"
        title="Share on WhatsApp"
      >
        <FaWhatsapp size={14} />
      </a>
      <a
        className="fc-shareby-btn"
        href={`mailto:?subject=${encodeURIComponent(summary)}&body=${encodeURIComponent(`${summary}\n\n${url}`)}`}
        title="Share by email"
      >
        <Mail size={14} />
      </a>
      <button
        type="button"
        className={`fc-shareby-btn ${copied ? 'is-done' : ''}`}
        onClick={copyLink}
        title={copied ? 'Link copied' : 'Copy link'}
      >
        {copied ? <Check size={14} /> : <Eye size={14} />}
      </button>
    </div>
  );
}
