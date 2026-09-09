<script>
  export let onClick = null
</script>

{#if onClick}
  <button class="wordmark wordmark-btn" on:click={onClick} aria-label="FoodPlus home">
    <span class="wordmark-food">Food</span><span class="wordmark-plus">Plus+</span>
  </button>
{:else}
  <span class="wordmark">
    <span class="wordmark-food">Food</span><span class="wordmark-plus">Plus+</span>
  </span>
{/if}

<style>
  .wordmark-btn {
    background: none;
    border: none;
    padding: 0;
    cursor: pointer;
    /* inherits .wordmark font/color from app.css */
  }
</style>
