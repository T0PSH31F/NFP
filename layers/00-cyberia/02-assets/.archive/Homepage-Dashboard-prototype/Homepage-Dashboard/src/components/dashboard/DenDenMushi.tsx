import { type ServiceStatus } from '@/data/services';

interface DenDenMushibProps {
  status: ServiceStatus;
  size?: number;
  hasAfro?: boolean;
}

const DenDenMushi = ({ status, size = 24, hasAfro = false }: DenDenMushibProps) => {
  const colors = {
    online: { body: '#39ff14', eye: '#fff', shell: '#2acd0e' },
    warning: { body: '#ff9500', eye: '#fff', shell: '#cc7700' },
    offline: { body: '#555', eye: '#333', shell: '#444' },
  };
  const c = colors[status];
  const animClass = status === 'online' ? 'animate-[denden-bob_1s_ease-in-out_infinite]' : status === 'warning' ? 'animate-[denden-bob_1.5s_ease-in-out_infinite]' : '';

  return (
    <div className={`relative inline-flex ${animClass}`} style={{ width: size, height: size }} aria-label={`Status: ${status}`}>
      <svg viewBox="0 0 32 32" width={size} height={size} fill="none">
        {/* Shell */}
        <ellipse cx="16" cy="18" rx="10" ry="8" fill={c.shell} opacity={0.6} />
        <ellipse cx="16" cy="16" rx="8" ry="6" fill={c.body} opacity={0.8} />
        {/* Body */}
        <ellipse cx="16" cy="20" rx="6" ry="4" fill={c.body} />
        {/* Eyes */}
        {status === 'offline' ? (
          <>
            <line x1="11" y1="14" x2="14" y2="16" stroke={c.eye} strokeWidth="1.5" />
            <line x1="14" y1="14" x2="11" y2="16" stroke={c.eye} strokeWidth="1.5" />
            <line x1="18" y1="14" x2="21" y2="16" stroke={c.eye} strokeWidth="1.5" />
            <line x1="21" y1="14" x2="18" y2="16" stroke={c.eye} strokeWidth="1.5" />
          </>
        ) : (
          <>
            <circle cx="12.5" cy="15" r="2" fill={c.eye} />
            <circle cx="19.5" cy="15" r="2" fill={c.eye} />
            <circle cx="13" cy="14.5" r="0.8" fill="#000" />
            <circle cx="20" cy="14.5" r="0.8" fill="#000" />
          </>
        )}
        {/* Antenna stalks */}
        <line x1="12" y1="12" x2="10" y2="7" stroke={c.body} strokeWidth="1.5" strokeLinecap="round" />
        <line x1="20" y1="12" x2="22" y2="7" stroke={c.body} strokeWidth="1.5" strokeLinecap="round" />
        <circle cx="10" cy="6" r="1.5" fill={c.body} />
        <circle cx="22" cy="6" r="1.5" fill={c.body} />
        {/* Sweat drop for warning */}
        {status === 'warning' && (
          <path d="M24 12 Q25 9 24 7" stroke="#00d9ff" strokeWidth="1" fill="none" opacity={0.7} />
        )}
        {/* Afro for Brook's Den Den Mushi */}
        {hasAfro && (
          <ellipse cx="16" cy="6" rx="8" ry="5" fill="#1a1a2e" stroke={c.body} strokeWidth="0.5" opacity={0.9} />
        )}
      </svg>
      {/* Glow effect */}
      {status === 'online' && (
        <div className="absolute inset-0 rounded-full" style={{ boxShadow: `0 0 8px ${c.body}40`, animation: 'jolly-pulse 2s ease-in-out infinite' }} />
      )}
    </div>
  );
};

export default DenDenMushi;
