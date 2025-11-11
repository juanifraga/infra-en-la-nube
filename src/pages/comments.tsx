import React, { useState, useEffect } from "react";
import Layout from "@theme/Layout";
import CommentForm from "@site/src/components/CommentForm";
import CommentCard from "@site/src/components/CommentCard";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";

interface Comment {
  id: string;
  name: string;
  email: string;
  comment: string;
  timestamp: string;
  avatarColor: string;
}

export default function Comments(): React.ReactElement {
  const API_URL = "/api";

  const [comments, setComments] = useState<Comment[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const avatarColors = [
    "hsla(208, 72%, 56%, 1.00)",
    "hsla(213, 72%, 56%, 1.00)",
    "hsla(217, 72%, 56%, 1.00)",
    "hsla(220, 72%, 56%, 1.00)",
    "hsla(227, 72%, 56%, 1.00)",
  ];

  const fetchComments = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(`${API_URL}/comments`);

      if (!response.ok) {
        throw new Error(`Failed to fetch comments: ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success && Array.isArray(data.data)) {
        const transformedComments = data.data.map((item: any) => ({
          id: item.id.toString(),
          name: item.name,
          email: item.email,
          comment: item.comment,
          timestamp: new Date(item.created_at).toLocaleString("en-US", {
            month: "short",
            day: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true,
          }),
          avatarColor:
            avatarColors[Math.floor(Math.random() * avatarColors.length)],
        }));

        setComments(transformedComments);
      }
    } catch (err) {
      console.error("Error fetching comments:", err);
      setError(err instanceof Error ? err.message : "Failed to load comments");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchComments();
  }, []);

  const handleCommentSubmit = async (newComment: {
    name: string;
    email: string;
    comment: string;
  }) => {
    try {
      const response = await fetch(`${API_URL}/comments`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(newComment),
      });

      if (!response.ok) {
        throw new Error(`Failed to post comment: ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success && data.data) {
        const comment: Comment = {
          id: data.data.id.toString(),
          name: data.data.name,
          email: data.data.email,
          comment: data.data.comment,
          timestamp: new Date(data.data.created_at).toLocaleString("en-US", {
            month: "short",
            day: "2-digit",
            year: "numeric",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true,
          }),
          avatarColor:
            avatarColors[Math.floor(Math.random() * avatarColors.length)],
        };

        setComments([comment, ...comments]);
      }
    } catch (err) {
      console.error("Error posting comment:", err);
      alert("Failed to post comment. Please try again.");
    }
  };

  return (
    <Layout
      title="Comments"
      description="Share your thoughts and connect with the community"
    >
      <div
        className="container"
        style={{
          paddingTop: "3rem",
          paddingBottom: "3rem",
          maxWidth: "900px",
          margin: "0 auto",
        }}
      >
        {/* Header */}
        <div style={{ textAlign: "center", marginBottom: "2rem" }}>
          <h1 style={{ marginBottom: "1rem" }}>Comments</h1>
          <p
            style={{
              color: "var(--ifm-color-emphasis-600)",
              fontSize: "1.125rem",
            }}
          >
            Share your thoughts and connect with the community. No registration
            required!
          </p>
        </div>

        {/* Comment Form */}
        <div
          style={{
            backgroundColor: "var(--ifm-card-background-color)",
            border: "1px solid var(--ifm-color-emphasis-300)",
            borderRadius: "8px",
            padding: "2rem",
            marginBottom: "2rem",
          }}
        >
          <h2
            style={{
              fontSize: "1.5rem",
              marginBottom: "1.5rem",
              marginTop: 0,
            }}
          >
            Add a Comment
          </h2>
          <CommentForm onCommentSubmit={handleCommentSubmit} />
        </div>

        {/* Comments List */}
        <div>
          <h2
            style={{
              fontSize: "1.75rem",
              marginBottom: "1.5rem",
              marginTop: 0,
            }}
          >
            Recent Comments ({comments.length})
          </h2>

          {loading && (
            <div
              style={{
                textAlign: "center",
                padding: "2rem",
                color: "var(--ifm-color-emphasis-600)",
              }}
            >
              Loading comments...
            </div>
          )}

          {error && (
            <div
              style={{
                backgroundColor: "var(--ifm-color-danger-contrast-background)",
                border: "1px solid var(--ifm-color-danger)",
                borderRadius: "8px",
                padding: "1rem",
                marginBottom: "1rem",
                color: "var(--ifm-color-danger)",
              }}
            >
              {error}
            </div>
          )}

          {!loading && !error && comments.length === 0 && (
            <div
              style={{
                textAlign: "center",
                padding: "3rem 2rem",
                backgroundColor: "var(--ifm-card-background-color)",
                border: "1px solid var(--ifm-color-emphasis-300)",
                borderRadius: "8px",
                color: "var(--ifm-color-emphasis-600)",
              }}
            >
              <p style={{ fontSize: "1.125rem", marginBottom: "0.5rem" }}>
                No comments yet
              </p>
              <p style={{ margin: 0 }}>Be the first to share your thoughts!</p>
            </div>
          )}

          {!loading && !error && comments.length > 0 && (
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
          )}
        </div>
      </div>
    </Layout>
  );
}
