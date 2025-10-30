import React, { useState } from 'react';
import Layout from '@theme/Layout';
import CommentForm from '@site/src/components/CommentForm';
import CommentCard from '@site/src/components/CommentCard';

interface Comment {
  id: string;
  name: string;
  email?: string;
  comment: string;
  timestamp: string;
  avatarColor: string;
}

export default function Comments(): React.ReactElement {
  const [comments, setComments] = useState<Comment[]>([
    {
      id: "1",
      name: "Alice Johnson",
      comment: "Great tutorial! This really helped me understand Docusaurus better.",
      timestamp: "Sep 29, 2025, 04:47 PM",
      avatarColor: "hsla(208, 72%, 56%, 1.00)",
    },
    {
      id: "2",
      name: "Bob Smith",
      comment: "Thanks for sharing this. Looking forward to more content!",
      timestamp: "Sep 29, 2025, 04:47 PM",
      avatarColor: "hsla(208, 62%, 46%, 1.00)",
    },
    {
      id: "3",
      name: "Carol Wilson",
      comment: "Very comprehensive guide. The step-by-step approach makes it easy to follow.",
      timestamp: "Sep 29, 2025, 04:47 PM",
      avatarColor: "hsla(213, 72%, 56%, 1.00)",
    },
  ]);

  const avatarColors = [
    "hsla(208, 72%, 56%, 1.00)",
    "hsla(213, 72%, 56%, 1.00)",
    "hsla(217, 72%, 56%, 1.00)",
    "hsla(220, 72%, 56%, 1.00)",
    "hsla(227, 72%, 56%, 1.00)",
  ];

  const handleCommentSubmit = (newComment: {
    name: string;
    email?: string;
    comment: string;
  }) => {
    const comment: Comment = {
      id: Date.now().toString(),
      ...newComment,
      timestamp: new Date().toLocaleString("en-US", {
        month: "short",
        day: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        hour12: true,
      }),
      avatarColor: avatarColors[Math.floor(Math.random() * avatarColors.length)],
    };

    setComments([comment, ...comments]);
  };

  return (
    <Layout
      title="Comments"
      description="Share your thoughts and connect with the community">
      <div className="container" style={{ 
        paddingTop: '3rem', 
        paddingBottom: '3rem',
        maxWidth: '900px',
        margin: '0 auto'
      }}>
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
          <h1 style={{ marginBottom: '1rem' }}>Comments</h1>
          <p style={{ 
            color: 'var(--ifm-color-emphasis-600)',
            fontSize: '1.125rem'
          }}>
            Share your thoughts and connect with the community. No registration required!
          </p>
        </div>

        {/* Comment Form */}
        <div style={{
          backgroundColor: 'var(--ifm-card-background-color)',
          border: '1px solid var(--ifm-color-emphasis-300)',
          borderRadius: '8px',
          padding: '2rem',
          marginBottom: '2rem'
        }}>
          <h2 style={{ 
            fontSize: '1.5rem', 
            marginBottom: '1.5rem',
            marginTop: 0
          }}>
            Add a Comment
          </h2>
          <CommentForm onCommentSubmit={handleCommentSubmit} />
        </div>

        {/* Comments List */}
        <div>
          <h2 style={{ 
            fontSize: '1.75rem', 
            marginBottom: '1.5rem',
            marginTop: 0
          }}>
            Recent Comments ({comments.length})
          </h2>
          <div>
            {comments.map((comment) => (
              <CommentCard
                key={comment.id}
                name={comment.name}
                comment={comment.comment}
                timestamp={comment.timestamp}
                avatarColor={comment.avatarColor}
              />
            ))}
          </div>
        </div>
      </div>
    </Layout>
  );
}
