Every product now has an optional customisation note (maximum 2,000 characters). Add to Cart and Buy Now save it with the selected variant. The cart and checkout show it, and checkout snapshots it to the order item before clearing the cart. Admin Orders → View order → Products & customisation shows each note, as do payment review and customer order history.

The database update supabase/updates/hood_customisation_notes.sql is already applied to cloth-web. Use the updated frontend; do not rerun the full backend setup. For a fresh installation, apply the notes update after the full setup.

The same colour/size with matching notes combines quantity. To use a different note for a variant already in the cart, remove the old cart item and add it again. This prevents silently overwriting customer instructions.

62 tests and production build pass. Database tests cover note persistence, different-note conflicts and the length limit. Live schema and authenticated/anonymous function permissions verified. Browser visual verification remains pending.
