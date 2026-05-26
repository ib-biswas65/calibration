export type Role = "admin" | "engineer" | "viewer";

export interface AuthMe {
  id: string;
  email: string;
  full_name: string;
  role: Role;
}
