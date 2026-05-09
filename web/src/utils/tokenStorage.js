const ACCESS_KEY  = 'cropsify_access';
const REFRESH_KEY = 'cropsify_refresh';

export const tokenStorage = {
  getAccess:    ()  => localStorage.getItem(ACCESS_KEY),
  getRefresh:   ()  => localStorage.getItem(REFRESH_KEY),
  setTokens:    (a, r) => {
    localStorage.setItem(ACCESS_KEY, a);
    localStorage.setItem(REFRESH_KEY, r);
  },
  clear:        ()  => {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
  },
  isExpired: (jwt) => {
    try {
      const payload = JSON.parse(atob(jwt.split('.')[1]));
      return (payload.exp * 1000) < (Date.now() + 30_000);
    } catch {
      return true;
    }
  },
};