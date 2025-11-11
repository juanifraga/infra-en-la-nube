import React, { useState } from "react";

interface CommentFormProps {
  onCommentSubmit: (comment: {
    name: string;
    email: string;
    comment: string;
  }) => void;
}

const CommentForm: React.FC<CommentFormProps> = ({ onCommentSubmit }) => {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [comment, setComment] = useState("");
  const [showToast, setShowToast] = useState(false);
  const [toastMessage, setToastMessage] = useState("");
  const [toastType, setToastType] = useState<"success" | "error">("success");
  const maxChars = 1000;

  const showNotification = (message: string, type: "success" | "error") => {
    setToastMessage(message);
    setToastType(type);
    setShowToast(true);
    setTimeout(() => setShowToast(false), 3000);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) {
      showNotification("Please enter your name", "error");
      return;
    }

    if (!email.trim()) {
      showNotification("Please enter your email", "error");
      return;
    }

    if (!comment.trim()) {
      showNotification("Please enter a comment", "error");
      return;
    }

    if (comment.length > maxChars) {
      showNotification(
        `Comment must be ${maxChars} characters or less`,
        "error"
      );
      return;
    }

    onCommentSubmit({
      name: name.trim(),
      email: email.trim(),
      comment: comment.trim(),
    });

    // Reset form
    setName("");
    setEmail("");
    setComment("");

    showNotification("Your comment has been added successfully!", "success");
  };

  const inputStyle: React.CSSProperties = {
    width: "100%",
    padding: "0.5rem 0.75rem",
    borderRadius: "6px",
    border: "1px solid var(--ifm-color-emphasis-300)",
    backgroundColor: "var(--ifm-background-color)",
    color: "var(--ifm-font-color-base)",
    fontSize: "1rem",
    fontFamily: "inherit",
  };

  const labelStyle: React.CSSProperties = {
    display: "block",
    marginBottom: "0.5rem",
    fontWeight: 500,
    fontSize: "0.875rem",
  };

  return (
    <>
      {showToast && (
        <div
          style={{
            position: "fixed",
            top: "20px",
            right: "20px",
            padding: "1rem 1.5rem",
            borderRadius: "8px",
            backgroundColor: toastType === "success" ? "#10b981" : "#ef4444",
            color: "white",
            boxShadow: "0 4px 6px rgba(0, 0, 0, 0.1)",
            zIndex: 9999,
            animation: "slideIn 0.3s ease-out",
          }}
        >
          {toastMessage}
        </div>
      )}
      <form
        onSubmit={handleSubmit}
        style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}
      >
        <div>
          <label htmlFor="name" style={labelStyle}>
            Name <span style={{ color: "#ef4444" }}>*</span>
          </label>
          <input
            id="name"
            type="text"
            placeholder="Your name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            style={inputStyle}
            maxLength={100}
          />
        </div>

        <div>
          <label htmlFor="email" style={labelStyle}>
            Email <span style={{ color: "#ef4444" }}>*</span>
          </label>
          <input
            id="email"
            type="email"
            placeholder="your.email@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={inputStyle}
            maxLength={255}
          />
        </div>

        <div>
          <label htmlFor="comment" style={labelStyle}>
            Comment <span style={{ color: "#ef4444" }}>*</span>
          </label>
          <textarea
            id="comment"
            placeholder="Share your thoughts..."
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            style={{
              ...inputStyle,
              minHeight: "120px",
              resize: "vertical",
            }}
            maxLength={maxChars}
          />
          <div
            style={{
              textAlign: "right",
              fontSize: "0.875rem",
              color: "var(--ifm-color-emphasis-600)",
              marginTop: "0.25rem",
            }}
          >
            {comment.length}/{maxChars} characters
          </div>
        </div>

        <button
          type="submit"
          style={{
            padding: "0.625rem 1.5rem",
            borderRadius: "6px",
            border: "none",
            backgroundColor: "var(--ifm-color-primary)",
            color: "white",
            fontSize: "1rem",
            fontWeight: 500,
            cursor: "pointer",
            transition: "opacity 0.2s",
            alignSelf: "flex-start",
          }}
          onMouseEnter={(e) => (e.currentTarget.style.opacity = "0.9")}
          onMouseLeave={(e) => (e.currentTarget.style.opacity = "1")}
        >
          Post Comment
        </button>
      </form>
      <style>{`
        @keyframes slideIn {
          from {
            transform: translateX(100%);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }
      `}</style>
    </>
  );
};

export default CommentForm;
