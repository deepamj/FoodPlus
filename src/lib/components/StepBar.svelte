<script>
  export let current = 1 // 1, 2, or 3

  const steps = [
    { n: 1, label: 'Add an address' },
    { n: 2, label: 'Enter details' },
    { n: 3, label: 'Add photos' },
  ]

  function stateOf(n) {
    if (n < current) return 'done'
    if (n === current) return 'active'
    return 'future'
  }
</script>

<div class="step-bar">
  {#each steps as step, i}
    <div class="step-row {stateOf(step.n)}">
      <div class="step-line-col">
        <div class="step-dot"></div>
        {#if i < steps.length - 1}
          <div class="step-connector"></div>
        {/if}
      </div>
      <span class="step-label">{step.n}. {step.label}</span>
    </div>
    <!-- slot for step content rendered inline -->
    {#if step.n === current}
      <div class="step-content">
        <slot />
      </div>
    {/if}
  {/each}
</div>
