module Definition.LogicalRelation.Substitution.Introductions.Natrec where

open import Definition.Untyped as U hiding (wk)
open import Definition.Untyped.Properties
open import Definition.Typed
import Definition.Typed.Weakening as T
open import Definition.Typed.Properties
open import Definition.Typed.RedSteps
open import Definition.LogicalRelation
open import Definition.LogicalRelation.Tactic
open import Definition.LogicalRelation.Weakening
open import Definition.LogicalRelation.Irrelevance
open import Definition.LogicalRelation.Properties
open import Definition.LogicalRelation.Substitution
open import Definition.LogicalRelation.Substitution.Properties
import Definition.LogicalRelation.Substitution.Irrelevance as S

open import Tools.Context

open import Data.Product
open import Data.Unit
open import Data.Empty
open import Data.Nat renaming (ℕ to Nat)

import Relation.Binary.PropositionalEquality as PE

open import Definition.LogicalRelation.Substitution.Introductions


natrec-subst* : ∀ {Γ C c g n n' l} → Γ ∙ ℕ ⊢ C → Γ ⊢ c ∷ C [ zero ]
              → Γ ⊢ g ∷ Π ℕ ▹ (C ▹▹ C [ suc (var zero) ]↑)
              → Γ ⊢ n ⇒* n' ∷ ℕ
              → ([ℕ] : Γ ⊩⟨ l ⟩ ℕ)
              → Γ ⊩⟨ l ⟩ n' ∷ ℕ / [ℕ]
              → (∀ {t t'} → Γ ⊩⟨ l ⟩ t  ∷ ℕ / [ℕ]
                          → Γ ⊩⟨ l ⟩ t' ∷ ℕ / [ℕ]
                          → Γ ⊩⟨ l ⟩ t ≡ t' ∷ ℕ / [ℕ]
                          → Γ ⊢ C [ t ] ≡ C [ t' ])
              → Γ ⊢ natrec C c g n ⇒* natrec C c g n' ∷ C [ n ]
natrec-subst* C c g (id x) [ℕ] [n'] prop = id (natrec C c g x)
natrec-subst* C c g (x ⇨ n⇒n') [ℕ] [n'] prop =
  let q , w = redSubst*Term n⇒n' [ℕ] [n']
      a , s = redSubstTerm x [ℕ] q
  in  natrec-subst C c g x ⇨ conv* (natrec-subst* C c g n⇒n' [ℕ] [n'] prop)
                   (prop q a (symEqTerm [ℕ] s))

natrecSucCaseLemma : ∀ {σ} (x : Nat) →
      (substComp (liftSubst σ)
        (wkSubst (step id)
        (consSubst (wk1Subst idSubst) (suc (var zero))))) x
      PE.≡
      (substComp (consSubst (wk1Subst idSubst) (suc (var zero)))
        (purge (step id) (liftSubst (liftSubst σ)))) x
natrecSucCaseLemma zero = PE.refl
natrecSucCaseLemma {σ} (suc x) = PE.trans (subst-wk (σ x))
                             (PE.sym (PE.trans (wkIndex-step (step id))
                                               (wk2subst (step (step id)) (σ x))))

natrecSucCase : ∀ σ F → Term.Π ℕ ▹
      (Π subst (liftSubst σ) F ▹
       subst (liftSubst (liftSubst σ)) (wk1 (F [ suc (var zero) ]↑)))
      PE.≡
      Π ℕ ▹
      (subst (liftSubst σ) F ▹▹
       subst (liftSubst σ) F [ suc (var zero) ]↑)
natrecSucCase σ F =
  let left = PE.trans (subst-wk (F [ suc (var zero) ]↑)) (PE.trans (substCompEq F) PE.refl)
      right = PE.trans (wk-subst (subst (liftSubst σ) F)) (PE.trans (substCompEq F) (substEq natrecSucCaseLemma F))
  in  PE.cong₂ Π_▹_ PE.refl
        (PE.cong₂ Π_▹_ PE.refl
          (PE.trans left (PE.sym right)))

natrecIrrelevantSubstLemma : ∀ F z s m σ (x : Nat) →
     (substComp (consSubst (λ x → var (suc x)) (suc (var 0)))
       (purge (step id)
        (substComp (liftSubst (liftSubst σ))
         (substComp (liftSubst (consSubst idSubst m))
          (consSubst idSubst
           (natrec (subst (liftSubst σ) F) (subst σ z) (subst σ s) m)))))) x
           PE.≡ (consSubst σ (suc m)) x
natrecIrrelevantSubstLemma F z s m σ zero = PE.cong suc (PE.trans (subst-wk m) (substIdEq m))
natrecIrrelevantSubstLemma F z s m σ (suc x) = PE.trans (subst-wk (U.wk (step id) (σ x))) (PE.trans (subst-wk (σ x)) (substIdEq (σ x)))

natrecIrrelevantSubst : ∀ F z s m σ →
      subst (consSubst σ (suc m)) F PE.≡
      subst (liftSubst (consSubst idSubst m))
      (subst (liftSubst (liftSubst σ)) (wk1 (F [ suc (var zero) ]↑)))
      [ natrec (subst (liftSubst σ) F) (subst σ z) (subst σ s) m ]
natrecIrrelevantSubst F z s m σ = PE.sym (PE.trans (substCompEq (subst (liftSubst (liftSubst σ))
        (U.wk (step id)
         (subst (consSubst (λ x → var (suc x)) (suc (var 0))) F))))
         (PE.trans (substCompEq (U.wk (step id)
        (subst (consSubst (λ x → var (suc x)) (suc (var 0))) F)))
        (PE.trans
           (subst-wk (subst (consSubst (λ x → var (suc x)) (suc (var 0))) F))
           (PE.trans (substCompEq F) (substEq (natrecIrrelevantSubstLemma F z s m σ) F)))))

natrecTerm : ∀ {F z s n Γ Δ σ l}
              ([Γ]  : ⊩ₛ Γ)
              ([F]  : Γ ∙ ℕ ⊩ₛ⟨ l ⟩ F / _∙_ {l = l} [Γ] (ℕₛ [Γ]))
              ([F₀] : Γ ⊩ₛ⟨ l ⟩ F [ zero ] / [Γ])
              ([F₊] : Γ ⊩ₛ⟨ l ⟩ Π ℕ ▹ (F ▹▹ F [ suc (var zero) ]↑) / [Γ])
              ([z]  : Γ ⊩ₛ⟨ l ⟩t z ∷ F [ zero ] / [Γ] / [F₀])
              ([s]  : Γ ⊩ₛ⟨ l ⟩t s ∷ Π ℕ ▹ (F ▹▹ F [ suc (var zero) ]↑) / [Γ] / [F₊])
              (⊢Δ   : ⊢ Δ)
              ([σ]  : Δ ⊩ₛ σ ∷ Γ / [Γ] / ⊢Δ)
              ([σn] : Δ ⊩⟨ l ⟩ n ∷ ℕ / ℕ (idRed:*: (ℕ ⊢Δ)))
            → Δ ⊩⟨ l ⟩ natrec (subst (liftSubst σ) F) (subst σ z) (subst σ s) n ∷ subst (liftSubst σ) F [ n ]
                / PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σn]))) --proj₁ ([Fₙ] ⊢Δ [σ])
natrecTerm {F} {z} {s} {n} {Γ} {Δ} {σ} {l} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] ℕ[ .(suc m) , d , suc {m} , [m] ] =
  let [ℕ] = ℕₛ {l = l} [Γ]
      [σℕ] = proj₁ ([ℕ] ⊢Δ [σ])
      ⊢ℕ = soundness (proj₁ ([ℕ] ⊢Δ [σ]))
      ⊢F = soundness (proj₁ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ])))
      ⊢z = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ])) (proj₁ ([z] ⊢Δ [σ])))
      ⊢s = PE.subst (λ x → Δ ⊢ subst σ s ∷ x) (natrecSucCase σ F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])))
      ⊢n = soundnessTerm {l = l} (ℕ ([ ⊢ℕ , ⊢ℕ , id ⊢ℕ ])) ℕ[ suc m , d , suc {m} , [m] ]
      ⊢m = soundnessTerm {l = l} [σℕ] [m]
      [σsm] = irrelevanceTerm {l = l} (ℕ (idRed:*: (ℕ ⊢Δ))) [σℕ] ℕ[ suc m , idRedTerm:*: (suc ⊢m) , suc , [m] ]
      [σn] = ℕ[ suc m , d , suc {m} , [m] ]
      [σn]' , [σn≡σsm] = redSubst*Term (redₜ d) [σℕ] [σsm]
      [σFₙ]' = proj₁ ([F] ⊢Δ ([σ] , [σn]))
      [σFₙ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) [σFₙ]'
      [σFₛₘ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma (suc m) σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σsm])))
      [Fₙ≡Fₛₘ] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                (PE.sym (singleSubstLemma (suc m) σ F)) [σFₙ]' [σFₙ]
                                (proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ] , [σsm]) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σsm]))
      [σFₘ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (PE.trans (substCompEq F) (substEq substConcatSingleton F))) (proj₁ ([F] ⊢Δ ([σ] , [m])))
      [σFₛₘ]' = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (natrecIrrelevantSubst F z s m σ) (proj₁ ([F] {σ = consSubst σ (suc m)} ⊢Δ ([σ] , [σsm])))
      [σF₊ₘ] = substSΠ₁ (proj₁ ([F₊] ⊢Δ [σ])) [σℕ] [m]
      natrecM = appTerm [σFₘ] [σFₛₘ]' [σF₊ₘ] (appTerm [σℕ] [σF₊ₘ] (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])) [m])
                        (natrecTerm {F} {z} {s} {m} {σ = σ} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [m])
      natrecM' = irrelevanceTerm' (PE.trans (PE.sym (natrecIrrelevantSubst F z s m σ)) (PE.sym (singleSubstLemma (suc m) σ F))) [σFₛₘ]' [σFₛₘ] natrecM
      reduction = natrec-subst* ⊢F ⊢z ⊢s (redₜ d) [σℕ] [σsm]
                    (λ {t} {t'} [t] [t'] [t≡t'] →
                       PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                 (PE.sym (singleSubstLemma t σ F))
                                 (PE.sym (singleSubstLemma t' σ F))
                                 (soundnessEq (proj₁ ([F] ⊢Δ ([σ] , [t])))
                                              (proj₂ ([F] ⊢Δ ([σ] , [t]))
                                                     ([σ] , [t'])
                                                     (reflSubst [Γ] ⊢Δ [σ] , [t≡t']))))
                  ⇨∷* (conv* (natrec-suc ⊢m ⊢F ⊢z ⊢s
                  ⇨   id (soundnessTerm [σFₛₘ] natrecM')) (sym (soundnessEq [σFₙ] [Fₙ≡Fₛₘ])))
  in  proj₁ (redSubst*Term reduction [σFₙ] (convTerm₂ [σFₙ] [σFₛₘ] [Fₙ≡Fₛₘ] natrecM'))
natrecTerm {F} {s = s} {n = n} {Γ = Γ} {Δ = Δ} {σ = σ} {l = l} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] ℕ[ .zero , d , zero , _ ] =
  let [ℕ] = ℕₛ {l = l} [Γ]
      [σℕ] = proj₁ ([ℕ] ⊢Δ [σ])
      ⊢ℕ = soundness (proj₁ ([ℕ] ⊢Δ [σ]))
      ⊢F = soundness (proj₁ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ])))
      ⊢z = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ])) (proj₁ ([z] ⊢Δ [σ])))
      ⊢s = PE.subst (λ x → Δ ⊢ subst σ s ∷ x) (natrecSucCase σ F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])))
      ⊢n = soundnessTerm {l = l} (ℕ ([ ⊢ℕ , ⊢ℕ , id ⊢ℕ ])) ℕ[ zero , d , zero , _ ]
      [σ0] = irrelevanceTerm {l = l} (ℕ (idRed:*: (ℕ ⊢Δ))) (proj₁ ([ℕ] ⊢Δ [σ]))  ℕ[ zero , idRedTerm:*: (zero ⊢Δ) , zero , _ ]
      [σn]' , [σn≡σ0] = redSubst*Term (redₜ d) (proj₁ ([ℕ] ⊢Δ [σ])) [σ0]
      [σn] = ℕ[ zero , d , zero , _ ]
      [σFₙ]' = proj₁ ([F] ⊢Δ ([σ] , [σn]))
      [σFₙ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) [σFₙ]'
      [σF₀] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma zero σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σ0])))
      [Fₙ≡F₀]' = proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ] , [σ0]) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σ0])
      [Fₙ≡F₀] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                (PE.sym (substCompEq F))
                                [σFₙ]' [σFₙ] [Fₙ≡F₀]'
      [Fₙ≡F₀]'' = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                  (PE.trans (substEq substConcatSingleton' F) (PE.sym (singleSubstLemma zero σ F)))
                                  [σFₙ]' [σFₙ] [Fₙ≡F₀]'
      [σz] = proj₁ ([z] ⊢Δ [σ])
      reduction = natrec-subst* ⊢F ⊢z ⊢s (redₜ d) (proj₁ ([ℕ] ⊢Δ [σ])) [σ0]
                    (λ {t} {t'} [t] [t'] [t≡t'] →
                       PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                 (PE.sym (singleSubstLemma t σ F))
                                 (PE.sym (singleSubstLemma t' σ F))
                                 (soundnessEq (proj₁ ([F] ⊢Δ ([σ] , [t])))
                                              (proj₂ ([F] ⊢Δ ([σ] , [t]))
                                                     ([σ] , [t'])
                                                     (reflSubst [Γ] ⊢Δ [σ] , [t≡t']))))
                  ⇨∷* (conv* (natrec-zero ⊢F ⊢z ⊢s ⇨ id ⊢z) (sym (soundnessEq [σFₙ] [Fₙ≡F₀]'')))
  in  proj₁ (redSubst*Term reduction [σFₙ] (convTerm₂ [σFₙ] (proj₁ ([F₀] ⊢Δ [σ])) [Fₙ≡F₀] [σz]))
natrecTerm {F} {s = s} {n = n} {Γ = Γ} {Δ = Δ} {σ = σ} {l = l} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] ℕ[ m , d , ne neM , ⊢m ] =
  let [ℕ] = ℕₛ {l = l} [Γ]
      [σℕ] = proj₁ ([ℕ] ⊢Δ [σ])
      [σn] = ℕ[ m , d , ne neM , ⊢m ]
      ⊢ℕ = soundness (proj₁ ([ℕ] ⊢Δ [σ]))
      ⊢F = soundness (proj₁ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ])))
      ⊢z = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ])) (proj₁ ([z] ⊢Δ [σ])))
      ⊢s = PE.subst (λ x → Δ ⊢ subst σ s ∷ x) (natrecSucCase σ F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])))
      ⊢n = soundnessTerm [σℕ] [σn]
      [σm] = neuTerm [σℕ] neM ⊢m
      [σn]' , [σn≡σm] = redSubst*Term (redₜ d) [σℕ] [σm]
      [σFₙ]' = proj₁ ([F] ⊢Δ ([σ] , [σn]))
      [σFₙ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) [σFₙ]'
      [σFₘ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma m σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σm])))
      [Fₙ≡Fₘ] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                (PE.sym (singleSubstLemma m σ F)) [σFₙ]' [σFₙ]
                                ((proj₂ ([F] ⊢Δ ([σ] , [σn]))) ([σ] , [σm]) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σm]))
      natrecM = neuTerm [σFₘ] (natrec neM) (natrec ⊢F ⊢z ⊢s ⊢m)
      reduction = natrec-subst* ⊢F ⊢z ⊢s (redₜ d) [σℕ] [σm]
                    (λ {t} {t'} [t] [t'] [t≡t'] →
                       PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                 (PE.sym (singleSubstLemma t σ F))
                                 (PE.sym (singleSubstLemma t' σ F))
                                 (soundnessEq (proj₁ ([F] ⊢Δ ([σ] , [t])))
                                              (proj₂ ([F] ⊢Δ ([σ] , [t]))
                                                     ([σ] , [t'])
                                                     (reflSubst [Γ] ⊢Δ [σ] , [t≡t']))))
  in  proj₁ (redSubst*Term reduction [σFₙ] (convTerm₂ [σFₙ] [σFₘ] [Fₙ≡Fₘ] natrecM))

natrec-congTerm : ∀ {F z s n m Γ Δ σ σ' l}
                  ([Γ]  : ⊩ₛ Γ)
                  ([F]  : Γ ∙ ℕ ⊩ₛ⟨ l ⟩ F / _∙_ {l = l} [Γ] (ℕₛ [Γ]))
                  ([F₀] : Γ ⊩ₛ⟨ l ⟩ F [ zero ] / [Γ])
                  ([F₊] : Γ ⊩ₛ⟨ l ⟩ Π ℕ ▹ (F ▹▹ F [ suc (var zero) ]↑) / [Γ])
                  ([z]  : Γ ⊩ₛ⟨ l ⟩t z ∷ F [ zero ] / [Γ] / [F₀])
                  ([s]  : Γ ⊩ₛ⟨ l ⟩t s ∷ Π ℕ ▹ (F ▹▹ F [ suc (var zero) ]↑) / [Γ] / [F₊])
                  (⊢Δ   : ⊢ Δ)
                  ([σ]  : Δ ⊩ₛ σ  ∷ Γ / [Γ] / ⊢Δ)
                  ([σ'] : Δ ⊩ₛ σ' ∷ Γ / [Γ] / ⊢Δ)
                  ([σ≡σ'] : Δ ⊩ₛ σ ≡ σ' ∷ Γ / [Γ] / ⊢Δ / [σ])
                  ([σn] : Δ ⊩⟨ l ⟩ n ∷ ℕ / ℕ (idRed:*: (ℕ ⊢Δ)))
                  ([σm] : Δ ⊩⟨ l ⟩ m ∷ ℕ / ℕ (idRed:*: (ℕ ⊢Δ)))
                  ([σn≡σm] : Δ ⊩⟨ l ⟩ n ≡ m ∷ ℕ / ℕ (idRed:*: (ℕ ⊢Δ)))
                → Δ ⊩⟨ l ⟩ natrec (subst (liftSubst σ) F) (subst σ z) (subst σ s) n
                         ≡ natrec (subst (liftSubst σ') F) (subst σ' z) (subst σ' s) m
                         ∷ subst (liftSubst σ) F [ n ]
                    / PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F))
                               (proj₁ ([F] ⊢Δ ([σ] , [σn])))
natrec-congTerm {F} {z} {s} {n} {m} {Γ} {Δ} {σ} {σ'} {l}
                [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ .(suc n') , d , suc {n'} , [n'] ] ℕ[ .(suc m') , d' , suc {m'} , [m'] ]
                ℕ≡[ .(suc n'') , .(suc m'') , d₁ , d₁' , t≡u , suc {n''} {m''} , [n''≡m''] ] =
  let n''≡n' = suc-PE-injectivity (whrDet* (redₜ d₁ , suc) (redₜ d , suc))
      m''≡m' = suc-PE-injectivity (whrDet* (redₜ d₁' , suc) (redₜ d' , suc))
      [ℕ] = ℕₛ {l = l} [Γ]
      [σℕ] = proj₁ ([ℕ] ⊢Δ [σ])
      [σ'ℕ] = proj₁ ([ℕ] ⊢Δ [σ'])
      [n'≡m'] = irrelevanceEqTerm'' n''≡n' m''≡m' PE.refl [σℕ] [σℕ] [n''≡m'']
      [σn] = ℕ[ suc n' , d , suc , [n'] ]
      [σ'm] = ℕ[ suc m' , d' , suc , [m'] ]
      [σn≡σ'm] = ℕ≡[ suc n'' , suc m'' , d₁ , d₁' , t≡u , suc , [n''≡m''] ]
      ⊢ℕ = soundness [σℕ]
      ⊢F = soundness (proj₁ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ])))
      ⊢z = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ])) (proj₁ ([z] ⊢Δ [σ])))
      ⊢s = PE.subst (λ x → Δ ⊢ subst σ s ∷ x) (natrecSucCase σ F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])))
      ⊢n = soundnessTerm {l = l} (ℕ ([ ⊢ℕ , ⊢ℕ , id ⊢ℕ ])) [σn]
      ⊢n' = soundnessTerm {l = l} [σℕ] [n']
      ⊢ℕ' = soundness [σ'ℕ]
      ⊢F' = soundness (proj₁ ([F] {σ = liftSubst σ'} (⊢Δ ∙ ⊢ℕ') (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ'])))
      ⊢z' = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ'])) (proj₁ ([z] ⊢Δ [σ'])))
      ⊢s' = PE.subst (λ x → Δ ⊢ subst σ' s ∷ x) (natrecSucCase σ' F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ'])) (proj₁ ([s] ⊢Δ [σ'])))
      ⊢m  = soundnessTerm {l = l} (ℕ ([ ⊢ℕ' , ⊢ℕ' , id ⊢ℕ' ])) [σ'm]
      ⊢m' = soundnessTerm {l = l} [σ'ℕ] [m']
      [σsn'] = irrelevanceTerm {l = l} (ℕ (idRed:*: (ℕ ⊢Δ))) [σℕ] ℕ[ suc n' , idRedTerm:*: (suc ⊢n') , suc , [n'] ]
      [σn]' , [σn≡σsn'] = redSubst*Term (redₜ d) [σℕ] [σsn']
      [σFₙ]' = proj₁ ([F] ⊢Δ ([σ] , [σn]))
      [σFₙ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) [σFₙ]'
      [σFₛₙ'] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma (suc n') σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σsn'])))
      [Fₙ≡Fₛₙ'] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                (PE.sym (singleSubstLemma (suc n') σ F)) [σFₙ]' [σFₙ]
                                (proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ] , [σsn']) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σsn']))
      [Fₙ≡Fₛₙ']' = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                   (natrecIrrelevantSubst F z s n' σ) [σFₙ]' [σFₙ]
                                   (proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ] , [σsn']) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σsn']))
      [σFₙ'] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (PE.trans (substCompEq F) (substEq substConcatSingleton F))) (proj₁ ([F] ⊢Δ ([σ] , [n'])))
      [σFₛₙ']' = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (natrecIrrelevantSubst F z s n' σ) (proj₁ ([F] {σ = consSubst σ (suc n')} ⊢Δ ([σ] , [σsn'])))
      [σF₊ₙ'] = substSΠ₁ (proj₁ ([F₊] ⊢Δ [σ])) [σℕ] [n']
      [σ'sm'] = irrelevanceTerm {l = l} (ℕ (idRed:*: (ℕ ⊢Δ))) [σ'ℕ] ℕ[ suc m' , idRedTerm:*: (suc ⊢m') , suc , [m'] ]
      [σ'm]' , [σ'm≡σ'sm'] = redSubst*Term (redₜ d') [σ'ℕ] [σ'sm']
      [σ'Fₘ]' = proj₁ ([F] ⊢Δ ([σ'] , [σ'm]))
      [σ'Fₘ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma m σ' F)) [σ'Fₘ]'
      [σ'Fₛₘ'] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma (suc m') σ' F)) (proj₁ ([F] ⊢Δ ([σ'] , [σ'sm'])))
      [Fₘ≡Fₛₘ'] = irrelevanceEq'' (PE.sym (singleSubstLemma m σ' F))
                                (PE.sym (singleSubstLemma (suc m') σ' F)) [σ'Fₘ]' [σ'Fₘ]
                                (proj₂ ([F] ⊢Δ ([σ'] , [σ'm])) ([σ'] , [σ'sm']) (reflSubst [Γ] ⊢Δ [σ'] , [σ'm≡σ'sm']))
      [σ'Fₘ'] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (PE.trans (substCompEq F) (substEq substConcatSingleton F))) (proj₁ ([F] ⊢Δ ([σ'] , [m'])))
      [σ'Fₛₘ']' = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (natrecIrrelevantSubst F z s m' σ') (proj₁ ([F] {σ = consSubst σ' (suc m')} ⊢Δ ([σ'] , [σ'sm'])))
      [σ'F₊ₘ'] = substSΠ₁ (proj₁ ([F₊] ⊢Δ [σ'])) [σ'ℕ] [m']
      [σFₙ'≡σ'Fₘ'] = irrelevanceEq'' (PE.sym (singleSubstLemma n' σ F))
                                     (PE.sym (singleSubstLemma m' σ' F))
                                     (proj₁ ([F] ⊢Δ ([σ] , [n']))) [σFₙ']
                                     (proj₂ ([F] ⊢Δ ([σ] , [n']))
                                            ([σ'] , [m']) ([σ≡σ'] , [n'≡m']))
      [σFₙ≡σ'Fₘ] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                   (PE.sym (singleSubstLemma m σ' F))
                                   (proj₁ ([F] ⊢Δ ([σ] , [σn]))) [σFₙ]
                                   (proj₂ ([F] ⊢Δ ([σ] , [σn]))
                                          ([σ'] , [σ'm]) ([σ≡σ'] , [σn≡σ'm]))
      natrecN = appTerm [σFₙ'] [σFₛₙ']' [σF₊ₙ'] (appTerm [σℕ] [σF₊ₙ'] (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])) [n'])
                        (natrecTerm {F} {z} {s} {n'} {σ = σ} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [n'])
      natrecN' = irrelevanceTerm' (PE.trans (PE.sym (natrecIrrelevantSubst F z s n' σ)) (PE.sym (singleSubstLemma (suc n') σ F))) [σFₛₙ']' [σFₛₙ'] natrecN
      natrecM = appTerm [σ'Fₘ'] [σ'Fₛₘ']' [σ'F₊ₘ'] (appTerm [σ'ℕ] [σ'F₊ₘ'] (proj₁ ([F₊] ⊢Δ [σ'])) (proj₁ ([s] ⊢Δ [σ'])) [m'])
                        (natrecTerm {F} {z} {s} {m'} {σ = σ'} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ'] [m'])
      natrecM' = irrelevanceTerm' (PE.trans (PE.sym (natrecIrrelevantSubst F z s m' σ')) (PE.sym (singleSubstLemma (suc m') σ' F))) [σ'Fₛₘ']' [σ'Fₛₘ'] natrecM
      appEq = convEqTerm₂ [σFₙ] [σFₛₙ']' [Fₙ≡Fₛₙ']'
                (app-congTerm [σFₙ'] [σFₛₙ']' [σF₊ₙ']
                  (app-congTerm [σℕ] [σF₊ₙ'] (proj₁ ([F₊] ⊢Δ [σ])) (proj₂ ([s] ⊢Δ [σ]) [σ'] [σ≡σ']) [n'] [m'] [n'≡m'])
                  (natrecTerm {F} {z} {s} {n'} {σ = σ} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [n'])
                  (convTerm₂ [σFₙ'] [σ'Fₘ'] [σFₙ'≡σ'Fₘ'] (natrecTerm {F} {z} {s} {m'} {σ = σ'} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ'] [m']))
                  (natrec-congTerm {F} {z} {s} {n'} {m'} {σ = σ} [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ'] [n'] [m'] [n'≡m']))
      reduction₁ = natrec-subst* ⊢F ⊢z ⊢s (redₜ d) [σℕ] [σsn']
                     (λ {t} {t'} [t] [t'] [t≡t'] →
                        PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                  (PE.sym (singleSubstLemma t σ F))
                                  (PE.sym (singleSubstLemma t' σ F))
                                  (soundnessEq (proj₁ ([F] ⊢Δ ([σ] , [t])))
                                               (proj₂ ([F] ⊢Δ ([σ] , [t]))
                                                      ([σ] , [t'])
                                                      (reflSubst [Γ] ⊢Δ [σ] , [t≡t']))))
                   ⇨∷* (conv* (natrec-suc ⊢n' ⊢F ⊢z ⊢s
                   ⇨   id (soundnessTerm [σFₛₙ'] natrecN')) (sym (soundnessEq [σFₙ] [Fₙ≡Fₛₙ'])))
      reduction₂ = natrec-subst* ⊢F' ⊢z' ⊢s' (redₜ d') [σ'ℕ] [σ'sm']
                     (λ {t} {t'} [t] [t'] [t≡t'] →
                        PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                  (PE.sym (singleSubstLemma t σ' F))
                                  (PE.sym (singleSubstLemma t' σ' F))
                                  (soundnessEq (proj₁ ([F] ⊢Δ ([σ'] , [t])))
                                               (proj₂ ([F] ⊢Δ ([σ'] , [t]))
                                                      ([σ'] , [t'])
                                                      (reflSubst [Γ] ⊢Δ [σ'] , [t≡t']))))
                   ⇨∷* (conv* (natrec-suc ⊢m' ⊢F' ⊢z' ⊢s'
                   ⇨   id (soundnessTerm [σ'Fₛₘ'] natrecM')) (sym (soundnessEq [σ'Fₘ] [Fₘ≡Fₛₘ'])))
      eq₁ = proj₂ (redSubst*Term reduction₁ [σFₙ] (convTerm₂ [σFₙ] [σFₛₙ'] [Fₙ≡Fₛₙ'] natrecN'))
      eq₂ = proj₂ (redSubst*Term reduction₂ [σ'Fₘ] (convTerm₂ [σ'Fₘ] [σ'Fₛₘ'] [Fₘ≡Fₛₘ'] natrecM'))
  in  transEqTerm [σFₙ] eq₁ (transEqTerm [σFₙ] appEq (convEqTerm₂ [σFₙ] [σ'Fₘ] [σFₙ≡σ'Fₘ] (symEqTerm [σ'Fₘ] eq₂)))
natrec-congTerm {F} {z} {s} {n} {m} {Γ} {Δ} {σ} {σ'} {l}
                [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ .zero , d , zero , prop ] ℕ[ .zero , d₁ , zero , prop₁ ]
                ℕ≡[ .zero , .zero , d₂ , d' , t≡u , zero , prop₂ ] =
  let [ℕ] = ℕₛ {l = l} [Γ]
      [σℕ] = proj₁ ([ℕ] ⊢Δ [σ])
      ⊢ℕ = soundness (proj₁ ([ℕ] ⊢Δ [σ]))
      ⊢F = soundness (proj₁ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ])))
      ⊢z = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ])) (proj₁ ([z] ⊢Δ [σ])))
      ⊢s = PE.subst (λ x → Δ ⊢ subst σ s ∷ x) (natrecSucCase σ F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])))
      ⊢F' = soundness (proj₁ ([F] {σ = liftSubst σ'} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ'])))
      ⊢z' = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ'])) (proj₁ ([z] ⊢Δ [σ'])))
      ⊢s' = PE.subst (λ x → Δ ⊢ subst σ' s ∷ x) (natrecSucCase σ' F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ'])) (proj₁ ([s] ⊢Δ [σ'])))
      ⊢n = soundnessTerm {l = l} (ℕ ([ ⊢ℕ , ⊢ℕ , id ⊢ℕ ])) ℕ[ zero , d , zero , _ ]
      [σ0] = irrelevanceTerm {l = l} (ℕ (idRed:*: (ℕ ⊢Δ))) (proj₁ ([ℕ] ⊢Δ [σ]))  ℕ[ zero , idRedTerm:*: (zero ⊢Δ) , zero , _ ]
      [σ'0] = irrelevanceTerm {l = l} (ℕ (idRed:*: (ℕ ⊢Δ))) (proj₁ ([ℕ] ⊢Δ [σ']))  ℕ[ zero , idRedTerm:*: (zero ⊢Δ) , zero , _ ]
      [σn]' , [σn≡σ0] = redSubst*Term (redₜ d) (proj₁ ([ℕ] ⊢Δ [σ])) [σ0]
      [σ'm]' , [σ'm≡σ'0] = redSubst*Term (redₜ d') (proj₁ ([ℕ] ⊢Δ [σ'])) [σ'0]
      [σn] = ℕ[ zero , d , zero , _ ]
      [σ'm] = ℕ[ zero , d' , zero , _ ]
      [σn≡σ'm] = ℕ≡[ zero , zero , d₂ , d' , t≡u , zero , prop₂ ]
      [σFₙ]' = proj₁ ([F] ⊢Δ ([σ] , [σn]))
      [σFₙ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) [σFₙ]'
      [σ'Fₘ]' = proj₁ ([F] ⊢Δ ([σ'] , [σ'm]))
      [σ'Fₘ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma m σ' F)) [σ'Fₘ]'
      [σFₙ≡σ'Fₘ] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                   (PE.sym (singleSubstLemma m σ' F))
                                   [σFₙ]' [σFₙ]
                                   (proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ'] , [σ'm])
                                          ([σ≡σ'] , [σn≡σ'm]))
      [σF₀] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma zero σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σ0])))
      [Fₙ≡F₀]' = proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ] , [σ0]) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σ0])
      [Fₙ≡F₀] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                (PE.sym (substCompEq F))
                                [σFₙ]' [σFₙ] [Fₙ≡F₀]'
      [Fₘ≡F₀]' = proj₂ ([F] ⊢Δ ([σ'] , [σ'm])) ([σ'] , [σ'0]) (reflSubst [Γ] ⊢Δ [σ'] , [σ'm≡σ'0])
      [Fₘ≡F₀] = irrelevanceEq'' (PE.sym (singleSubstLemma m σ' F))
                                (PE.sym (substCompEq F))
                                [σ'Fₘ]' [σ'Fₘ] [Fₘ≡F₀]'
      [Fₙ≡F₀]'' = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                  (PE.trans (substEq substConcatSingleton' F) (PE.sym (singleSubstLemma zero σ F)))
                                  [σFₙ]' [σFₙ] [Fₙ≡F₀]'
      [Fₘ≡F₀]'' = irrelevanceEq'' (PE.sym (singleSubstLemma m σ' F))
                                  (PE.trans (substEq substConcatSingleton' F) (PE.sym (singleSubstLemma zero σ' F)))
                                  [σ'Fₘ]' [σ'Fₘ] [Fₘ≡F₀]'
      [σz] = proj₁ ([z] ⊢Δ [σ])
      [σ'z] = proj₁ ([z] ⊢Δ [σ'])
      [σz≡σ'z] = convEqTerm₂ [σFₙ] (proj₁ ([F₀] ⊢Δ [σ])) [Fₙ≡F₀] (proj₂ ([z] ⊢Δ [σ]) [σ'] [σ≡σ'])
      reduction₁ = natrec-subst* ⊢F ⊢z ⊢s (redₜ d) (proj₁ ([ℕ] ⊢Δ [σ])) [σ0]
                    (λ {t} {t'} [t] [t'] [t≡t'] →
                       PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                 (PE.sym (singleSubstLemma t σ F))
                                 (PE.sym (singleSubstLemma t' σ F))
                                 (soundnessEq (proj₁ ([F] ⊢Δ ([σ] , [t])))
                                              (proj₂ ([F] ⊢Δ ([σ] , [t]))
                                                     ([σ] , [t'])
                                                     (reflSubst [Γ] ⊢Δ [σ] , [t≡t']))))
                  ⇨∷* (conv* (natrec-zero ⊢F ⊢z ⊢s ⇨ id ⊢z) (sym (soundnessEq [σFₙ] [Fₙ≡F₀]'')))
      reduction₂ = natrec-subst* ⊢F' ⊢z' ⊢s' (redₜ d') (proj₁ ([ℕ] ⊢Δ [σ'])) [σ'0]
                    (λ {t} {t'} [t] [t'] [t≡t'] →
                       PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                 (PE.sym (singleSubstLemma t σ' F))
                                 (PE.sym (singleSubstLemma t' σ' F))
                                 (soundnessEq (proj₁ ([F] ⊢Δ ([σ'] , [t])))
                                              (proj₂ ([F] ⊢Δ ([σ'] , [t]))
                                                     ([σ'] , [t'])
                                                     (reflSubst [Γ] ⊢Δ [σ'] , [t≡t']))))
                  ⇨∷* (conv* (natrec-zero ⊢F' ⊢z' ⊢s' ⇨ id ⊢z') (sym (soundnessEq [σ'Fₘ] [Fₘ≡F₀]'')))
      eq₁ = proj₂ (redSubst*Term reduction₁ [σFₙ] (convTerm₂ [σFₙ] (proj₁ ([F₀] ⊢Δ [σ])) [Fₙ≡F₀] [σz]))
      eq₂ = proj₂ (redSubst*Term reduction₂ [σ'Fₘ] (convTerm₂ [σ'Fₘ] (proj₁ ([F₀] ⊢Δ [σ'])) [Fₘ≡F₀] [σ'z]))
  in  transEqTerm [σFₙ] eq₁ (transEqTerm [σFₙ] [σz≡σ'z] (convEqTerm₂ [σFₙ] [σ'Fₘ] [σFₙ≡σ'Fₘ] (symEqTerm [σ'Fₘ] eq₂)))
natrec-congTerm {F} {z} {s} {n} {m} {Γ} {Δ} {σ} {σ'} {l}
                [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ n' , d , ne neN' , ⊢n' ] ℕ[ m' , d' , ne neM' , ⊢m' ]
                ℕ≡[ n'' , m'' , d₁ , d₁' , t≡u , ne x₂ x₃ , prop₂ ] =
  let n''≡n' = whrDet* (redₜ d₁ , ne x₂) (redₜ d , ne neN')
      m''≡m' = whrDet* (redₜ d₁' , ne x₃) (redₜ d' , ne neM')
      [ℕ] = ℕₛ {l = l} [Γ]
      [σℕ] = proj₁ ([ℕ] ⊢Δ [σ])
      [σ'ℕ] = proj₁ ([ℕ] ⊢Δ [σ'])
      [σn] = ℕ[ n' , d , ne neN' , ⊢n' ]
      [σ'm] = ℕ[ m' , d' , ne neM' , ⊢m' ]
      [σn≡σ'm] = ℕ≡[ n'' , m'' , d₁ , d₁' , t≡u , ne x₂ x₃ , prop₂ ]
      ⊢ℕ = soundness (proj₁ ([ℕ] ⊢Δ [σ]))
      [σF] = proj₁ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ]))
      ⊢F = soundness [σF]
      ⊢z = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero)
                    (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ])) (proj₁ ([z] ⊢Δ [σ])))
      ⊢s = PE.subst (λ x → Δ ⊢ subst σ s ∷ x) (natrecSucCase σ F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ])) (proj₁ ([s] ⊢Δ [σ])))
      ⊢F' = soundness (proj₁ ([F] {σ = liftSubst σ'} (⊢Δ ∙ ⊢ℕ) (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ'])))
      ⊢z' = PE.subst (λ x → _ ⊢ _ ∷ x) (singleSubstLift F zero) (soundnessTerm (proj₁ ([F₀] ⊢Δ [σ'])) (proj₁ ([z] ⊢Δ [σ'])))
      ⊢s' = PE.subst (λ x → Δ ⊢ subst σ' s ∷ x) (natrecSucCase σ' F) (soundnessTerm (proj₁ ([F₊] ⊢Δ [σ'])) (proj₁ ([s] ⊢Δ [σ'])))
      ⊢F≡F' = soundnessEq [σF] (proj₂ ([F] {σ = liftSubst σ} (⊢Δ ∙ ⊢ℕ)
                                           (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ]))
                                      {σ' = liftSubst σ'}
                                      (liftSubstS {F = ℕ} [Γ] ⊢Δ [ℕ] [σ'])
                                      (liftSubstSEq {F = ℕ} [Γ] ⊢Δ [ℕ] [σ] [σ≡σ']))
      ⊢z≡z' = PE.subst (λ x → _ ⊢ _ ≡ _ ∷ x) (singleSubstLift F zero)
                       (soundnessTermEq (proj₁ ([F₀] ⊢Δ [σ])) (proj₂ ([z] ⊢Δ [σ]) [σ'] [σ≡σ']))
      ⊢s≡s' = PE.subst (λ x → Δ ⊢ subst σ s ≡ subst σ' s ∷ x) (natrecSucCase σ F)
                       (soundnessTermEq (proj₁ ([F₊] ⊢Δ [σ])) (proj₂ ([s] ⊢Δ [σ]) [σ'] [σ≡σ']))
      ⊢n = soundnessTerm [σℕ] [σn]
      [σn'] = neuTerm [σℕ] neN' ⊢n'
      [σn]' , [σn≡σn'] = redSubst*Term (redₜ d) [σℕ] [σn']
      [σFₙ]' = proj₁ ([F] ⊢Δ ([σ] , [σn]))
      [σFₙ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n σ F)) [σFₙ]'
      [σFₙ'] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n' σ F)) (proj₁ ([F] ⊢Δ ([σ] , [σn'])))
      [Fₙ≡Fₙ'] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                (PE.sym (singleSubstLemma n' σ F)) [σFₙ]' [σFₙ]
                                ((proj₂ ([F] ⊢Δ ([σ] , [σn]))) ([σ] , [σn']) (reflSubst [Γ] ⊢Δ [σ] , [σn≡σn']))
      [σ'm'] = neuTerm [σ'ℕ] neM' ⊢m'
      [σ'm]' , [σ'm≡σ'm'] = redSubst*Term (redₜ d') [σ'ℕ] [σ'm']
      [σ'Fₘ]' = proj₁ ([F] ⊢Δ ([σ'] , [σ'm]))
      [σ'Fₘ] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma m σ' F)) [σ'Fₘ]'
      [σ'Fₘ'] = PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma m' σ' F)) (proj₁ ([F] ⊢Δ ([σ'] , [σ'm'])))
      [Fₘ≡Fₘ'] = irrelevanceEq'' (PE.sym (singleSubstLemma m σ' F))
                                 (PE.sym (singleSubstLemma m' σ' F)) [σ'Fₘ]' [σ'Fₘ]
                                 ((proj₂ ([F] ⊢Δ ([σ'] , [σ'm]))) ([σ'] , [σ'm']) (reflSubst [Γ] ⊢Δ [σ'] , [σ'm≡σ'm']))
      [σFₙ≡σ'Fₘ] = irrelevanceEq'' (PE.sym (singleSubstLemma n σ F))
                                   (PE.sym (singleSubstLemma m σ' F))
                                   [σFₙ]' [σFₙ]
                                   (proj₂ ([F] ⊢Δ ([σ] , [σn])) ([σ'] , [σ'm])
                                          ([σ≡σ'] , [σn≡σ'm]))
      [σFₙ'≡σ'Fₘ'] = transEq [σFₙ'] [σFₙ] [σ'Fₘ'] (symEq [σFₙ] [σFₙ'] [Fₙ≡Fₙ'])
                             (transEq [σFₙ] [σ'Fₘ] [σ'Fₘ'] [σFₙ≡σ'Fₘ] [Fₘ≡Fₘ'])
      natrecN = neuTerm [σFₙ'] (natrec neN') (natrec ⊢F ⊢z ⊢s ⊢n')
      natrecM = neuTerm [σ'Fₘ'] (natrec neM') (natrec ⊢F' ⊢z' ⊢s' ⊢m')
      natrecN≡M = convEqTerm₂ [σFₙ] [σFₙ'] [Fₙ≡Fₙ']
                              (neuEqTerm [σFₙ'] (natrec neN') (natrec neM')
                                         (natrec ⊢F ⊢z ⊢s ⊢n'
                                         , conv (natrec ⊢F' ⊢z' ⊢s' ⊢m')
                                                (sym (soundnessEq [σFₙ'] [σFₙ'≡σ'Fₘ']))
                                         , natrec-cong ⊢F≡F' ⊢z≡z' ⊢s≡s'
                                                       (PE.subst₂ (λ x y → _ ⊢ x ≡ y ∷ _) n''≡n' m''≡m' prop₂)))
      reduction₁ = natrec-subst* ⊢F ⊢z ⊢s (redₜ d) [σℕ] [σn']
                     (λ {t} {t'} [t] [t'] [t≡t'] →
                        PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                  (PE.sym (singleSubstLemma t σ F))
                                  (PE.sym (singleSubstLemma t' σ F))
                                  (soundnessEq (proj₁ ([F] ⊢Δ ([σ] , [t])))
                                               (proj₂ ([F] ⊢Δ ([σ] , [t]))
                                                      ([σ] , [t'])
                                                      (reflSubst [Γ] ⊢Δ [σ] , [t≡t']))))
      reduction₂ = natrec-subst* ⊢F' ⊢z' ⊢s' (redₜ d') [σ'ℕ] [σ'm']
                     (λ {t} {t'} [t] [t'] [t≡t'] →
                        PE.subst₂ (λ x y → _ ⊢ x ≡ y)
                                  (PE.sym (singleSubstLemma t σ' F))
                                  (PE.sym (singleSubstLemma t' σ' F))
                                  (soundnessEq (proj₁ ([F] ⊢Δ ([σ'] , [t])))
                                               (proj₂ ([F] ⊢Δ ([σ'] , [t]))
                                                      ([σ'] , [t'])
                                                      (reflSubst [Γ] ⊢Δ [σ'] , [t≡t']))))
      eq₁ = proj₂ (redSubst*Term reduction₁ [σFₙ] (convTerm₂ [σFₙ] [σFₙ'] [Fₙ≡Fₙ'] natrecN))
      eq₂ = proj₂ (redSubst*Term reduction₂ [σ'Fₘ] (convTerm₂ [σ'Fₘ] [σ'Fₘ'] [Fₘ≡Fₘ'] natrecM))
  in  transEqTerm [σFₙ] eq₁ (transEqTerm [σFₙ] natrecN≡M (convEqTerm₂ [σFₙ] [σ'Fₘ] [σFₙ≡σ'Fₘ] (symEqTerm [σ'Fₘ] eq₂)))
-- Refuting cases
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                [σn] ℕ[ .zero , d₁ , zero , prop₁ ]
                ℕ≡[ _ , _ , d₂ , d' , t≡u , suc , prop₂ ] =
  ⊥-elim (zero≢suc (whrDet* (redₜ d₁ , zero) (redₜ d' , suc)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                [σn] ℕ[ n , d₁ , ne x , prop₁ ]
                ℕ≡[ _ , _ , d₂ , d' , t≡u , suc , prop₂ ] =
  ⊥-elim (suc≢ne x (whrDet* (redₜ d' , suc) (redₜ d₁ , ne x)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ .zero , d , zero , prop ] [σm]
                ℕ≡[ _ , _ , d₁ , d' , t≡u , suc , prop₂ ] =
  ⊥-elim (zero≢suc (whrDet* (redₜ d , zero) (redₜ d₁ , suc)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ n , d , ne x , prop ] [σm]
                ℕ≡[ _ , _ , d₁ , d' , t≡u , suc , prop₂ ] =
  ⊥-elim (suc≢ne x (whrDet* (redₜ d₁ , suc) (redₜ d , ne x)))

natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ _ , d , suc , prop ] [σm]
                ℕ≡[ .zero , .zero , d₂ , d' , t≡u , zero , prop₂ ] =
  ⊥-elim (zero≢suc (whrDet* (redₜ d₂ , zero) (redₜ d , suc)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                [σn] ℕ[ _ , d₁ , suc , prop₁ ]
                ℕ≡[ .zero , .zero , d₂ , d' , t≡u , zero , prop₂ ] =
  ⊥-elim (zero≢suc (whrDet* (redₜ d' , zero) (redₜ d₁ , suc)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                [σn] ℕ[ n , d₁ , ne x , prop₁ ]
                ℕ≡[ .zero , .zero , d₂ , d' , t≡u , zero , prop₂ ] =
  ⊥-elim (zero≢ne x (whrDet* (redₜ d' , zero) (redₜ d₁ , ne x)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ n , d , ne x , prop ] [σm]
                ℕ≡[ .zero , .zero , d₂ , d' , t≡u , zero , prop₂ ] =
  ⊥-elim (zero≢ne x (whrDet* (redₜ d₂ , zero) (redₜ d , ne x)))

natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ _ , d , suc , prop ] [σm]
                ℕ≡[ n₁ , n' , d₂ , d' , t≡u , ne x x₁ , prop₂ ] =
  ⊥-elim (suc≢ne x (whrDet* (redₜ d , suc) (redₜ d₂ , ne x)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                ℕ[ .zero , d , zero , prop ] [σm]
                ℕ≡[ n , n' , d₂ , d' , t≡u , ne x x₁ , prop₂ ] =
  ⊥-elim (zero≢ne x (whrDet* (redₜ d , zero) (redₜ d₂ , ne x)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                [σn] ℕ[ _ , d₁ , suc , prop₁ ]
                ℕ≡[ n₁ , n' , d₂ , d' , t≡u , ne x₁ x₂ , prop₂ ] =
  ⊥-elim (suc≢ne x₂ (whrDet* (redₜ d₁ , suc) (redₜ d' , ne x₂)))
natrec-congTerm [Γ] [F] [F₀] [F₊] [z] [s] ⊢Δ [σ] [σ'] [σ≡σ']
                [σn] ℕ[ .zero , d₁ , zero , prop₁ ]
                ℕ≡[ n , n' , d₂ , d' , t≡u , ne x₁ x₂ , prop₂ ] =
  ⊥-elim (zero≢ne x₂ (whrDet* (redₜ d₁ , zero) (redₜ d' , ne x₂)))

natrecₛ : ∀ {F z s n Γ} ([Γ] : ⊩ₛ Γ)
          ([ℕ]  : Γ ⊩ₛ⟨ ¹ ⟩ ℕ / [Γ])
          ([F]  : Γ ∙ ℕ ⊩ₛ⟨ ¹ ⟩ F / [Γ] ∙ [ℕ])
          ([F₀] : Γ ⊩ₛ⟨ ¹ ⟩ F [ zero ] / [Γ])
          ([F₊] : Γ ⊩ₛ⟨ ¹ ⟩ Π ℕ ▹ (F ▹▹ F [ suc (var zero) ]↑) / [Γ])
          ([Fₙ] : Γ ⊩ₛ⟨ ¹ ⟩ F [ n ] / [Γ])
        → Γ ⊩ₛ⟨ ¹ ⟩t z ∷ F [ zero ] / [Γ] / [F₀]
        → Γ ⊩ₛ⟨ ¹ ⟩t s ∷ Π ℕ ▹ (F ▹▹ F [ suc (var zero) ]↑) / [Γ] / [F₊]
        → ([n] : Γ ⊩ₛ⟨ ¹ ⟩t n ∷ ℕ / [Γ] / [ℕ])
        → Γ ⊩ₛ⟨ ¹ ⟩t natrec F z s n ∷ F [ n ] / [Γ] / [Fₙ]
natrecₛ {F} {z} {s} {n} [Γ] [ℕ] [F] [F₀] [F₊] [Fₙ] [z] [s] [n] {Δ = Δ} {σ = σ}  ⊢Δ [σ] =
  let
    [F]' = S.irrelevance {A = F} (_∙_ {A = ℕ} [Γ] [ℕ]) (_∙_ {l = ¹} [Γ] (ℕₛ [Γ])) [F]
    [σn]' = irrelevanceTerm {l' = ¹} (proj₁ ([ℕ] ⊢Δ [σ])) (ℕ (idRed:*: (ℕ ⊢Δ))) (proj₁ ([n] ⊢Δ [σ]))
    n' = subst σ n
    eqPrf = PE.trans (singleSubstLemma n' σ F) (PE.sym (PE.trans (substCompEq F) (substEq substConcatSingleton' F)))
  in irrelevanceTerm' eqPrf (PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n' σ F)) (proj₁ ([F]' ⊢Δ ([σ] , [σn]'))))
                        (proj₁ ([Fₙ] ⊢Δ [σ]))
                   (natrecTerm {F} {z} {s} {n'} {σ = σ} [Γ]
                               [F]'
                               [F₀] [F₊] [z] [s] ⊢Δ [σ]
                               [σn]')
 ,
  (λ {σ'} [σ'] [σ≡σ'] →
     let [σ'n]' = irrelevanceTerm {l' = ¹} (proj₁ ([ℕ] ⊢Δ [σ'])) (ℕ (idRed:*: (ℕ ⊢Δ))) (proj₁ ([n] ⊢Δ [σ']))
         [σn≡σ'n] = irrelevanceEqTerm {l' = ¹} (proj₁ ([ℕ] ⊢Δ [σ])) (ℕ (idRed:*: (ℕ ⊢Δ))) (proj₂ ([n] ⊢Δ [σ]) [σ'] [σ≡σ'])
     in  irrelevanceEqTerm' eqPrf (PE.subst (λ x → _ ⊩⟨ _ ⟩ x) (PE.sym (singleSubstLemma n' σ F)) (proj₁ ([F]' ⊢Δ ([σ] , [σn]')))) (proj₁ ([Fₙ] ⊢Δ [σ]))
                            (natrec-congTerm {F} {z} {s} {n'} {subst σ' n} {σ = σ}
                                             [Γ] [F]' [F₀] [F₊] [z] [s] ⊢Δ
                                             [σ] [σ'] [σ≡σ'] [σn]' [σ'n]' [σn≡σ'n]))