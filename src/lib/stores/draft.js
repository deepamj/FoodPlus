import { writable } from 'svelte/store'

// Wizard state for the Report Surplus flow
export const draft = writable({
  // Step 1
  address: '',
  lat: null,
  lng: null,
  // Step 2
  items: [{ name: '', quantity: '', is_veg: true }],
  expires_at: '',
  // Step 3
  photos: [],       // File objects
  photoPreviews: [] // object URLs for display
})

export function resetDraft() {
  draft.set({
    address: '', lat: null, lng: null,
    items: [{ name: '', quantity: '', is_veg: true }],
    expires_at: '',
    photos: [], photoPreviews: []
  })
}
