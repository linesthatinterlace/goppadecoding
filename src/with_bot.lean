import tactic.basic
import algebra.order.monoid
open function

universe u
variable {α : Type u}

namespace with_top
variables {a b c d : with_top α}

-- Generalisations that are possible.

lemma not_top_le_coe' [has_le α] (a : α) : ¬ (⊤ : with_top α) ≤ ↑a :=
by simp [has_le.le, some_eq_coe]

lemma ne_top_of_lt' [has_lt α] (h : a < b) : a ≠ ⊤ :=
by { rintro rfl, simpa [has_lt.lt, some_eq_coe] using h }

lemma lt_top_of_ne_top [has_lt α] (h : a ≠ ⊤) : a < ⊤ :=
by { cases a, exact (h rfl).elim, exact some_lt_none _ }

lemma lt_top_iff_ne_top' [has_lt α] : a < ⊤ ↔ a ≠ ⊤ := ⟨λ H, ne_top_of_lt' H, lt_top_of_ne_top⟩

-- cv/con instances, propagated

instance contravariant_class_add_lt' [has_add α] [has_lt α]
[contravariant_class α α (+) (<)] : contravariant_class (with_top α) (with_top α) (+) (<) :=
begin
  refine ⟨λ a b c hbc, _⟩,
  cases a; cases b; try {exact (not_none_lt _ hbc).elim},
  cases c, exact coe_lt_top _,
  simp only [some_eq_coe, ← coe_add, coe_lt_coe] at ⊢ hbc, exact lt_of_add_lt_add_left hbc
end

instance contravariant_class_swap_add_lt [has_add α] [has_lt α]
[contravariant_class α α (swap (+)) (<)] :
contravariant_class (with_top α) (with_top α) (swap (+)) (<) :=
begin
  refine ⟨λ a b c hbc, _⟩, 
  cases a; cases b; try {exact (not_none_lt _ hbc).elim},
  cases c, exact coe_lt_top _ ,
  simp only [swap, some_eq_coe, ← coe_add, coe_lt_coe] at ⊢ hbc, exact lt_of_add_lt_add_right hbc
end

instance covariant_class_add_le [has_add α] [has_le α]
[covariant_class α α (+) (≤)] : covariant_class (with_top α) (with_top α) (+) (≤) :=
begin
  refine ⟨λ a b c hbc, _⟩,
  cases a; cases c; try {exact le_none},
  cases b, exact (not_top_le_coe' _ hbc).elim,
  rw some_le_some at hbc, simp only [some_eq_coe, ← coe_add, coe_le_coe, hbc, add_le_add_left]
end

instance covariant_class_swap_add_le [has_add α] [has_le α]
[covariant_class α α (swap (+)) (≤)] : covariant_class (with_top α) (with_top α) (swap (+)) (≤) :=
begin
  refine ⟨λ a b c hbc, _⟩,
  cases a; cases c; try {exact le_none},
  cases b, exact (not_top_le_coe' _ hbc).elim,
  rw some_le_some at hbc,
  simp only [swap, some_eq_coe, ← coe_add, coe_le_coe, hbc, add_le_add_right]
end

-- The "missing" theorems: "nearly cv/con".

protected theorem add_lt_add_left [has_add α] [has_lt α] [covariant_class α α (+) (<)]
(bc : b < c) (ha : a ≠ ⊤) : a + b < a + c :=
begin
  lift a to α using ha,
  cases b, exact (not_none_lt _ bc).elim,
  cases c, exact coe_lt_top _,
  rw some_lt_some at bc, simp only [bc, some_eq_coe, ← coe_add, coe_lt_coe],
  exact add_lt_add_left bc _,
end

protected theorem add_lt_add_right [has_add α] [has_lt α] [covariant_class α α (swap (+)) (<)]
(bc : b < c) (ha : a ≠ ⊤) : b + a < c + a :=
begin
  lift a to α using ha,
  cases b, exact (not_none_lt _ bc).elim,
  cases c, exact coe_lt_top _,
  rw some_lt_some at bc, simp only [bc, some_eq_coe, ← coe_add, coe_lt_coe],
  exact add_lt_add_right bc _,
end

protected theorem le_of_add_le_add_left [has_add α] [has_le α] [contravariant_class α α (+) (≤)]
(ha : a ≠ ⊤) (hbc : a + b ≤ a + c) : b ≤ c :=
begin
  lift a to α using ha,
  cases c; try {exact le_none},
  cases b, exact (not_top_le_coe' _ hbc).elim,
  simp only [some_eq_coe, ← coe_add, coe_le_coe] at hbc, rw some_le_some,
  exact le_of_add_le_add_left hbc,
end

protected theorem le_of_add_le_add_right [has_add α] [has_le α]
[contravariant_class α α (swap (+)) (≤)]
(ha : a ≠ ⊤) (hbc : b + a ≤ c + a) : b ≤ c :=
begin
  lift a to α using ha,
  cases c; try {exact le_none},
  cases b, exact (not_top_le_coe' _ hbc).elim,
  simp only [some_eq_coe, ← coe_add, coe_le_coe] at hbc, rw some_le_some,
  exact le_of_add_le_add_right hbc
end

-- Using the "missing theorems" along with the instances.

protected lemma add_lt_add_iff_left' [has_add α] [has_lt α]
[covariant_class α α (+) (<)] [contravariant_class α α (+) (<)]
(ha : a ≠ ⊤) : a + b < a + c ↔ b < c :=
⟨λ hbc, lt_of_add_lt_add_left hbc, λ hbc, with_top.add_lt_add_left hbc ha⟩

protected lemma add_lt_add_iff_right' [has_add α] [has_lt α]
[covariant_class α α (swap (+)) (<)] [contravariant_class α α (swap (+)) (<)]
(ha : a ≠ ⊤) : b + a < c + a ↔ b < c :=
⟨λ hbc, lt_of_add_lt_add_right hbc, λ hbc, with_top.add_lt_add_right hbc ha⟩

protected lemma add_le_add_iff_left [has_add α] [has_le α]
[covariant_class α α (+) (≤)] [contravariant_class α α (+) (≤)]
(ha : a ≠ ⊤) : a + b ≤ a + c ↔ b ≤ c :=
⟨λ hbc, with_top.le_of_add_le_add_left ha hbc, λ hbc, add_le_add_left hbc a⟩

protected lemma add_le_add_iff_right [has_add α] [has_le α]
[covariant_class α α (swap (+)) (≤)] [contravariant_class α α (swap (+)) (≤)]
(ha : a ≠ ⊤) : b + a ≤ c + a ↔ b ≤ c :=
⟨λ hbc, with_top.le_of_add_le_add_right ha hbc, λ hbc, add_le_add_right hbc a⟩

-- add_lt_add lemmas. Many, MANY options.

theorem add_lt_add_of_lt_of_lt_of_ne_left_top [has_add α] [preorder α]
[covariant_class α α (+) (<)] [covariant_class α α (swap (+)) (<)]
(hb : b ≠ ⊤) (hab : a < b) (hcd : c < d) : a + c < b + d :=
calc  a + c < b + c : with_top.add_lt_add_right hab (ne_top_of_lt hcd)
      ...   < b + d : with_top.add_lt_add_left hcd hb

theorem add_lt_add_of_lt_of_lt_of_ne_right_top [has_add α] [preorder α]
[covariant_class α α (+) (<)] [covariant_class α α (swap (+)) (<)]
(hd : d ≠ ⊤) (hab : a < b) (hcd : c < d) : a + c < b + d :=
calc  a + c < a + d : with_top.add_lt_add_left hcd (ne_top_of_lt hab)
      ...   < b + d : with_top.add_lt_add_right hab hd

theorem add_lt_add_of_lt_of_lt_of_cov_lt_cov_swap_lt [has_add α] [preorder α]
[covariant_class α α (+) (<)] [covariant_class α α (swap (+)) (<)]
(hab : a < b) (hcd : c < d) : a + c < b + d :=
begin
  cases b,
  { cases d,
    { rw [none_eq_top, add_top, ← @top_add _ _ c],
      apply with_top.add_lt_add_right hab, exact ne_top_of_lt' hcd },
    { exact add_lt_add_of_lt_of_lt_of_ne_right_top (coe_ne_top) hab hcd }
  }, exact add_lt_add_of_lt_of_lt_of_ne_left_top (coe_ne_top) hab hcd
end

theorem add_lt_add_of_lt_of_lt_cov_lt [has_add α] [preorder α]
[covariant_class α α (+) (<)] [covariant_class α α (swap (+)) (≤)]
(hab : a < b) (hcd : c < d) : a + c < b + d :=
calc  a + c < a + d : with_top.add_lt_add_left hcd (ne_top_of_lt hab)
      ...   ≤ b + d : add_le_add_right hab.le _

theorem add_lt_add_of_lt_of_lt_cov_swap_lt [has_add α] [preorder α]
[covariant_class α α (+) (≤)] [covariant_class α α (swap (+)) (<)]
(hab : a < b) (hcd : c < d) : a + c < b + d :=
calc  a + c < b + c : with_top.add_lt_add_right hab (ne_top_of_lt hcd)
      ...   ≤ b + d : add_le_add_left hcd.le b

theorem add_lt_add_of_le_of_lt_of_left_ne_bot [has_add α] [preorder α]
[covariant_class α α (+) (<)] [covariant_class α α (swap (+)) (≤)]
(ha : a ≠ ⊤) (hab : a ≤ b) (hcd : c < d) : a + c < b + d :=
calc  a + c < a + d : with_top.add_lt_add_left hcd ha
      ...   ≤ b + d : add_le_add_right hab _

theorem add_lt_add_of_le_of_lt_of_right_ne_bot [has_add α] [preorder α]
[covariant_class α α (+) (<)] [covariant_class α α (swap (+)) (≤)]
(hb : b ≠ ⊤) (hab : a ≤ b) (hcd : c < d) : a + c < b + d :=
calc  a + c ≤ b + c : add_le_add_right hab _
      ...   < b + d : with_top.add_lt_add_left hcd hb

theorem add_lt_add_of_lt_of_le_of_left_ne_bot [has_add α] [preorder α]
[covariant_class α α (+) (≤)] [covariant_class α α (swap (+)) (<)]
(hc : c ≠ ⊤) (hab : a < b) (hcd : c ≤ d) : a + c < b + d :=
calc  a + c < b + c : with_top.add_lt_add_right hab hc
      ...   ≤ b + d : add_le_add_left hcd _

theorem add_lt_add_of_lt_of_le_of_right_ne_bot [has_add α] [preorder α]
[covariant_class α α (+) (≤)] [covariant_class α α (swap (+)) (<)]
(hd : d ≠ ⊤) (hab : a < b) (hcd : c ≤ d) : a + c < b + d :=
calc  a + c ≤ a + d : add_le_add_left hcd _
      ...   < b + d : with_top.add_lt_add_right hab hd

end with_top

namespace with_bot

--- Need to add equivalent instances and lemmas (most of which will be straightforward applications of order_dual).

end with_bot