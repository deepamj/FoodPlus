<script>
  import Router, { push, router } from 'svelte-spa-router'
  import { wrap } from 'svelte-spa-router/wrap'
  import { get } from 'svelte/store'
  import { authStore } from './lib/stores/auth.js'
  import Landing   from './routes/Landing.svelte'
  import Auth      from './routes/Auth.svelte'
  import Step1     from './routes/report/Step1Address.svelte'
  import Step2     from './routes/report/Step2Details.svelte'
  import Step3     from './routes/report/Step3Photos.svelte'
  import Browse    from './routes/collect/Browse.svelte'
  import Claim     from './routes/collect/Claim.svelte'
  import Dashboard from './routes/donor/Dashboard.svelte'

  // Redirect to /auth, remembering where the user was headed
  async function requireAuth(detail) {
    if (get(authStore).user) return true
    if (get(authStore).loading) {
      await new Promise(resolve => {
        const unsub = authStore.subscribe(s => { if (!s.loading) { unsub(); resolve() } })
      })
      if (get(authStore).user) return true
    }
    push('/auth?next=' + encodeURIComponent(detail.location))
    return false
  }

  function goReport() { push('/report/1') }
  function goCollect() { push('/collect') }
  function goHome() { push('/') }

  // After auth, return to where the user was headed (?next=), else home
  function waitForUser(timeout = 8000) {
    return new Promise(resolve => {
      let done = false
      const finish = (user) => { if (!done) { done = true; clearTimeout(t); unsub(); resolve(user) } }
      const t = setTimeout(() => finish(get(authStore).user), timeout)
      const unsub = authStore.subscribe(s => { if (s.user) finish(s.user) })
    })
  }

  async function afterAuth() {
    const user = await waitForUser()
    if (!user) { push('/'); return }
    const qs = router.querystring || ''
    const next = new URLSearchParams(qs).get('next')
    push(next || '/')
  }

  const landingProps = { goReport, goCollect, onHome: goHome }

  const routes = {
    '/': wrap({ component: Landing, props: landingProps }),
    '/auth': wrap({ component: Auth, props: { onAuth: afterAuth, onBack: goHome, onHome: goHome } }),

    '/report/1': wrap({
      component: Step1,
      conditions: [requireAuth],
      props: { onNext: () => push('/report/2'), onBack: goHome, onHome: goHome },
    }),
    '/report/2': wrap({
      component: Step2,
      conditions: [requireAuth],
      props: { onNext: () => push('/report/3'), onBack: () => push('/report/1'), onHome: goHome },
    }),
    '/report/3': wrap({
      component: Step3,
      conditions: [requireAuth],
      props: { onDone: () => push('/donor'), onBack: () => push('/report/2'), onHome: goHome },
    }),

    '/donor': wrap({
      component: Dashboard,
      conditions: [requireAuth],
      props: { onNewPost: goReport, onLogout: goHome, onHome: goHome },
    }),

    '/collect': wrap({
      component: Browse,
      conditions: [requireAuth],
      props: { onSelect: (post) => push('/claim/' + post.id), onBack: goHome, onHome: goHome },
    }),
    '/claim/:id': wrap({
      component: Claim,
      conditions: [requireAuth],
      props: { onDone: () => push('/collect'), onBack: () => push('/collect'), onHome: goHome },
    }),

    '*': wrap({ component: Landing, props: landingProps }),
  }
</script>

<div id="app">
  {#if $authStore.loading}
    <div class="spinner" style="margin-top:40vh"></div>
  {:else}
    <Router {routes} />
  {/if}
</div>