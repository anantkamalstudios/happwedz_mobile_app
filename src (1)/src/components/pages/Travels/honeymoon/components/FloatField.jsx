/**
 * TripJack's floating-label inputs, used on every field of the booking flow.
 *
 * The portal's markup is `.floating-label > input.input-floating-lebel +
 * label.select-lebel-class + span.character-length`, and the label lifts when
 * the field is focused or filled. It drives that off `:placeholder-shown`,
 * which cannot work for `<select>` or `<input type="date">` — both always
 * report a value — so the filled state is passed down as a class instead and
 * one component covers every field on the page.
 */

/** Lifts the label whenever the control holds something, whatever its type. */
const filled = (value) => value !== undefined && value !== null && String(value) !== '';

export function FloatField({
  id,
  label,
  value,
  onChange,
  type = 'text',
  maxLength,
  counter = false,
  error,
  info,
  uppercase = false,
  alwaysFloat = false,
  ...rest
}) {
  const isFilled = filled(value);
  return (
    <div className={`float-wrap${info ? ' has-info' : ''}`}>
      <div
        className={[
          'floating-label',
          isFilled || alwaysFloat ? 'has-value' : '',
          error ? 'has-error' : '',
        ].filter(Boolean).join(' ')}
      >
        <input
          id={id}
          type={type}
          className="input-floating-lebel"
          value={value ?? ''}
          onChange={onChange}
          maxLength={maxLength}
          placeholder={label}
          style={uppercase ? { textTransform: 'uppercase' } : undefined}
          {...rest}
        />
        <label htmlFor={id} className="select-lebel-class">{label}</label>
        {counter && maxLength ? (
          <span className="character-length">{String(value || '').length}/{maxLength}</span>
        ) : null}
      </div>
      {info ? (
        <span className="name-info-btn" title={info} aria-label={info}>i</span>
      ) : null}
      {error ? <div className="float-error">{error}</div> : null}
    </div>
  );
}

/**
 * The portal's `.float-selectbox`: caret on the right and the label parked in
 * the floated position, since a select is never empty in the way a text field
 * is.
 */
export function FloatSelect({ id, label, value, onChange, options = [], error, ...rest }) {
  return (
    <div className="float-wrap">
      <div className={`float-selectbox${error ? ' has-error' : ''}`}>
        <label htmlFor={id} className="select-label">{label}</label>
        <select
          id={id}
          className="main-select"
          value={value ?? ''}
          onChange={onChange}
          {...rest}
        >
          {options.map((o) => {
            const val = typeof o === 'string' ? o : o.value;
            const text = typeof o === 'string' ? o : o.label;
            return <option key={val} value={val}>{text}</option>;
          })}
        </select>
        <i className="fonticon-caret" aria-hidden="true" />
      </div>
      {error ? <div className="float-error">{error}</div> : null}
    </div>
  );
}

export default FloatField;
