export type AdminAccess =
  | { status: 'authorized'; userId: string }
  | { status: 'unauthenticated' | 'forbidden' | 'unavailable' };

export interface AdminIdentitySource {
  verifiedUser(): Promise<{ id: string } | null>;
  accessProfile(): Promise<unknown>;
}

/** Both checks run server-side for each request. Cookie claims are never authority. */
export async function authorizeAdmin(source: AdminIdentitySource): Promise<AdminAccess> {
  try {
    const user = await source.verifiedUser();
    if (!user) return { status: 'unauthenticated' };
    const profile = await source.accessProfile();
    if (typeof profile !== 'object' || profile === null) return { status: 'forbidden' };
    const data = profile as Record<string, unknown>;
    if (data.user_id !== user.id || !Array.isArray(data.roles) || !data.roles.includes('admin')) {
      return { status: 'forbidden' };
    }
    return { status: 'authorized', userId: user.id };
  } catch {
    return { status: 'unavailable' };
  }
}
