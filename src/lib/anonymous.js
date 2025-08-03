// Anonymous collection support utilities
export class AnonymousSession {
  constructor() {
    this.sessionId = this.getOrCreateSessionId();
  }

  getOrCreateSessionId() {
    let sessionId = localStorage.getItem('typavibe_anon_session');
    if (!sessionId) {
      sessionId = 'anon_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
      localStorage.setItem('typavibe_anon_session', sessionId);
    }
    return sessionId;
  }

  getSessionId() {
    return this.sessionId;
  }

  clearSession() {
    localStorage.removeItem('typavibe_anon_session');
  }

  // Store anonymous collections in localStorage
  saveAnonymousCollection(collection) {
    const collections = this.getAnonymousCollections();
    collections.push({
      ...collection,
      sessionId: this.sessionId,
      createdAt: new Date().toISOString()
    });
    localStorage.setItem('typavibe_anon_collections', JSON.stringify(collections));
  }

  getAnonymousCollections() {
    const stored = localStorage.getItem('typavibe_anon_collections');
    return stored ? JSON.parse(stored) : [];
  }

  getCollectionBySlug(slug) {
    const collections = this.getAnonymousCollections();
    return collections.find(c => c.slug === slug && c.sessionId === this.sessionId);
  }

  updateCollection(slug, updates) {
    const collections = this.getAnonymousCollections();
    const index = collections.findIndex(c => c.slug === slug && c.sessionId === this.sessionId);
    if (index !== -1) {
      collections[index] = { ...collections[index], ...updates };
      localStorage.setItem('typavibe_anon_collections', JSON.stringify(collections));
      return collections[index];
    }
    return null;
  }

  deleteCollection(slug) {
    const collections = this.getAnonymousCollections();
    const filtered = collections.filter(c => !(c.slug === slug && c.sessionId === this.sessionId));
    localStorage.setItem('typavibe_anon_collections', JSON.stringify(filtered));
  }
}

export const anonymousSession = new AnonymousSession(); 