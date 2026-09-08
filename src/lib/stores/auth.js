import { writable } from 'svelte/store'
import { supabase } from '../supabase.js'

export const authStore = writable({ user: null, profile: null, loading: true })

export async function loadProfile(user) {
  if (!user) {
    authStore.set({ user: null, profile: null, loading: false })
    return
  }
  const { data: profile } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', user.id)
    .single()
  authStore.set({ user, profile, loading: false })
}

// Bootstrap on module load
supabase.auth.getSession().then(({ data: { session } }) => {
  loadProfile(session?.user ?? null)
})

supabase.auth.onAuthStateChange((_event, session) => {
  loadProfile(session?.user ?? null)
})
