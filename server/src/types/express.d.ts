declare global {
  namespace Express {
    interface Request {
      user?: { id: string; email: string };
      portal?: {
        projectId: string;
        email?: string;
        clientName?: string;
      };
    }
  }
}

export {};
