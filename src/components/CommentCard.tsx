import React from 'react';

interface CommentCardProps {
  name: string;
  comment: string;
  timestamp: string;
  avatarColor: string;
}

const CommentCard: React.FC<CommentCardProps> = ({ name, comment, timestamp, avatarColor }) => {
  const getInitials = (name: string) => {
    const parts = name.split(" ");
    if (parts.length >= 2) {
      return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  };

  return (
    <div style={{
      backgroundColor: 'var(--ifm-card-background-color)',
      border: '1px solid var(--ifm-color-emphasis-300)',
      borderRadius: '8px',
      padding: '1.5rem',
      marginBottom: '1rem'
    }}>
      <div style={{ display: 'flex', alignItems: 'start', gap: '1rem' }}>
        <div
          style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            backgroundColor: avatarColor,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'white',
            fontWeight: 'bold',
            fontSize: '14px',
            flexShrink: 0
          }}
        >
          {getInitials(name)}
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
            <h3 style={{ margin: 0, fontWeight: 600, fontSize: '1rem' }}>{name}</h3>
          </div>
          <p style={{ 
            margin: 0, 
            fontSize: '0.875rem', 
            color: 'var(--ifm-color-emphasis-600)',
            marginBottom: '0.75rem'
          }}>
            {timestamp}
          </p>
          <p style={{ 
            margin: 0, 
            lineHeight: 1.6,
            color: 'var(--ifm-font-color-base)'
          }}>
            {comment}
          </p>
        </div>
      </div>
    </div>
  );
};

export default CommentCard;
