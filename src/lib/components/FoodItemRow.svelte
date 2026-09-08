<script>
  export let item = { name: '', quantity: '', is_veg: true }
  export let canRemove = false
  export let onRemove = () => {}
</script>

<div class="food-item-row">
  <div class="row-top">
    <input
      class="input"
      style="flex:1"
      placeholder="Food Item"
      bind:value={item.name}
    />
    <div class="veg-toggle">
      <button
        type="button"
        class:active-veg={item.is_veg}
        on:click={() => (item.is_veg = true)}
      >Veg</button>
      <button
        type="button"
        class:active-nonveg={!item.is_veg}
        on:click={() => (item.is_veg = false)}
      >Non Veg</button>
    </div>
  </div>
  <div class="row-bottom">
    <input
      class="input"
      style="flex:1"
      type="number"
      min="1"
      placeholder="Quantity (No. of parcels)"
      bind:value={item.quantity}
    />
    {#if canRemove}
      <button type="button" class="remove-btn" on:click={onRemove} aria-label="Remove item">✕</button>
    {/if}
  </div>
</div>
