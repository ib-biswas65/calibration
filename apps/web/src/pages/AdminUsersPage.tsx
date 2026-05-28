import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Copy } from "lucide-react";
import { useState } from "react";
import { ApiError, apiFetch } from "../api/client";
import type { UserOut } from "../api/types";
import { ConfirmDialog } from "../components/ConfirmDialog";
import { useToast } from "../components/Toast";
import styles from "./AdminUsersPage.module.css";

export function AdminUsersPage() {
  const qc = useQueryClient();
  const { toast } = useToast();
  const [showInvite, setShowInvite] = useState(false);
  const [email, setEmail] = useState("");
  const [fullName, setFullName] = useState("");
  const [role, setRole] = useState("engineer");
  const [setupUrl, setSetupUrl] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [confirmDisable, setConfirmDisable] = useState<UserOut | null>(null);

  const { data: users = [], isLoading } = useQuery<UserOut[]>({
    queryKey: ["users"],
    queryFn: () => apiFetch<UserOut[]>("/api/auth/users"),
  });

  const patchMutation = useMutation({
    mutationFn: ({ id, body }: { id: string; body: { role?: string; disabled?: boolean } }) =>
      apiFetch(`/api/auth/users/${id}`, { method: "PATCH", json: body }),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ["users"] }); },
    onError: () => toast("Failed to update user", "error"),
  });

  async function handleInvite(e: React.FormEvent) {
    e.preventDefault();
    try {
      const res = await apiFetch<{ user_id: string; setup_url: string }>("/api/auth/users", {
        method: "POST",
        json: { email, full_name: fullName, role },
      });
      setSetupUrl(res.setup_url);
      qc.invalidateQueries({ queryKey: ["users"] });
      toast("User created", "success");
      setEmail(""); setFullName(""); setRole("engineer");
    } catch (err) {
      toast(err instanceof ApiError && err.status === 409 ? "Email already registered" : "Failed to create user", "error");
    }
  }

  function handleCopyUrl() {
    if (!setupUrl) return;
    const full = `${window.location.origin}${setupUrl}`;
    navigator.clipboard.writeText(full).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  function handleToggleDisable(u: UserOut) {
    if (!u.disabled) {
      setConfirmDisable(u);
    } else {
      patchMutation.mutate({ id: u.id, body: { disabled: false } });
    }
  }

  return (
    <div className={styles.page}>
      {confirmDisable && (
        <ConfirmDialog
          title="Disable user?"
          message={`${confirmDisable.full_name} (${confirmDisable.email}) will no longer be able to sign in.`}
          confirmLabel="Disable"
          destructive
          onConfirm={() => {
            patchMutation.mutate({ id: confirmDisable.id, body: { disabled: true } });
            setConfirmDisable(null);
          }}
          onCancel={() => setConfirmDisable(null)}
        />
      )}

      <div className={styles.header}>
        <h2 className={styles.heading}>User Management</h2>
        <button className={styles.btnPrimary} onClick={() => { setShowInvite(!showInvite); setSetupUrl(null); }}>
          {showInvite ? "Cancel" : "+ Invite user"}
        </button>
      </div>

      {showInvite && (
        <form className={styles.inviteForm} onSubmit={handleInvite}>
          <label className={styles.field}>
            <span>Email <span className={styles.required}>*</span></span>
            <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
          </label>
          <label className={styles.field}>
            <span>Full name <span className={styles.required}>*</span></span>
            <input required value={fullName} onChange={(e) => setFullName(e.target.value)} />
          </label>
          <label className={styles.field}>
            <span>Role</span>
            <select value={role} onChange={(e) => setRole(e.target.value)}>
              <option value="viewer">Viewer</option>
              <option value="engineer">Engineer</option>
              <option value="admin">Admin</option>
            </select>
          </label>
          <button type="submit" className={styles.btnPrimary}>Create user</button>
          {setupUrl && (
            <div className={styles.setupUrl}>
              <strong>Share this setup link with the user:</strong>
              <div className={styles.setupUrlRow}>
                <code className={styles.setupUrlCode}>{window.location.origin}{setupUrl}</code>
                <button type="button" className={styles.copyBtn} onClick={handleCopyUrl} aria-label="Copy setup link">
                  {copied ? <Check size={14} /> : <Copy size={14} />}
                  {copied ? "Copied" : "Copy"}
                </button>
              </div>
            </div>
          )}
        </form>
      )}

      {isLoading ? (
        <p>Loading…</p>
      ) : (
        <table className={styles.table}>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className={u.disabled ? styles.disabled : ""}>
                <td>{u.full_name}</td>
                <td>{u.email}</td>
                <td>
                  <select
                    value={u.role}
                    onChange={(e) => patchMutation.mutate({ id: u.id, body: { role: e.target.value } })}
                    className={styles.roleSelect}
                  >
                    <option value="viewer">Viewer</option>
                    <option value="engineer">Engineer</option>
                    <option value="admin">Admin</option>
                  </select>
                </td>
                <td>{u.disabled ? "Disabled" : "Active"}</td>
                <td>
                  <button
                    className={styles.toggleBtn}
                    onClick={() => handleToggleDisable(u)}
                  >
                    {u.disabled ? "Enable" : "Disable"}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
