<script>
  import Wordmark from '../lib/components/Wordmark.svelte'
  export let goReport = () => {}
  export let goCollect = () => {}
</script>

<div id="landing-page">
  <!-- Decorative accent strip -->
  <div class="landing-accent-strip" aria-hidden="true"></div>

  <div class="page-header" style="padding-bottom:0">
    <Wordmark />
  </div>

  <!-- Clean food photo — no text baked in -->
  <img
    class="landing-hero-img"
    src="/hero.jpg"
    alt="Assorted surplus food containers ready for redistribution"
    fetchpriority="high"
    on:error={(e) => e.currentTarget.style.display='none'}
  />

  <div class="landing-body">
    <h1 class="landing-headline">
      Smart surplus management<br>for a <mark>hunger-free tomorrow.</mark>
    </h1>
    <p class="landing-sub">
      At FoodPlus, we connect restaurants and caterers with local NGOs to turn
      surplus food into nourishing meals for the community.
    </p>

    <h2 class="landing-cta-heading">Get Started</h2>

    <div class="landing-cta-grid">
      <div class="landing-cta-col">
        <p>Are you a caterer, restaurant, or a volunteer?</p>
        <button id="btn-report-surplus" class="btn btn-primary" style="border-radius:var(--radius-xs);font-size:.9rem;padding:12px 16px" on:click={goReport}>
          Report Surplus
        </button>
      </div>
      <div class="landing-cta-col">
        <p>Are you an NGO, charity, or a food bank?</p>
        <button id="btn-collect-surplus" class="btn btn-primary" style="border-radius:var(--radius-xs);font-size:.9rem;padding:12px 16px" on:click={goCollect}>
          Collect Surplus
        </button>
      </div>
    </div>
  </div>
</div>

<style>
  .landing-accent-strip {
    width: 100%;
    height: 6px;
    background: linear-gradient(90deg, var(--accent) 0%, var(--accent-light) 50%, var(--accent-muted) 100%);
    flex-shrink: 0;
  }
</style>
