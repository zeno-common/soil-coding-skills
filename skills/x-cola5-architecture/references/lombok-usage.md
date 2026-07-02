# Lombok Usage

## Annotation Reference

| Layer | Type | Use | Forbid | Reason |
|-------|------|-----|--------|--------|
| domain | Entity | `@Getter` | `@Data` `@Setter` `@Builder` | Protect internal consistency |
| domain | ValueObject(V) | `@Getter @EqualsAndHashCode` | `@Data` `@Setter` | Immutable |
| domain | Event | `@Getter @EqualsAndHashCode` | `@Data` `@Setter` | Immutable |
| domain | DomainService | `@RequiredArgsConstructor` | — | Constructor injection |
| app | Cmd/Qry/VO | `@Data @Builder` | — | Pure data carrier |
| app | Service/Executor | `@RequiredArgsConstructor` | — | Constructor injection |
| infra | DO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` | — | ORM needs no-arg ctor |
| infra | GatewayImpl/Client | `@RequiredArgsConstructor` | — | Constructor injection |
| client | DTO | `@Data @Builder @NoArgsConstructor @AllArgsConstructor` | — | Deserialization needs no-arg ctor |
| adapter | Controller/Http/Rpc | `@RequiredArgsConstructor` | — | Constructor injection |

## @Slf4j

| Layer | Allowed |
|-------|:-------:|
| domain | ❌ |
| client | ❌ |
| app | ✅ |
| infrastructure | ✅ |
| adapter | ✅ |

## @Builder

| Type | Allowed | Reason |
|------|:-------:|--------|
| Cmd/Qry/VO/DTO/DO | ✅ | Pure data carrier |
| Entity | ❌ | Bypasses business rules |
| ValueObject/Event | ❌ | Use explicit constructor for invariants |

## @EqualsAndHashCode

| Type | Needed | Note |
|------|:------:|------|
| ValueObject | ✅ | Equality by attributes |
| DomainEvent | ✅ | Equality by attributes |
| Entity | ❌ | Equality by ID, attribute equality is wrong semantics |
| DTO/Cmd/Qry/VO/DO | — | `@Data` already includes it |

## Mandatory

1. Entity MUST NOT use `@Data` / `@Setter` / `@Builder`
2. ValueObject MUST NOT use `@Setter`, fields MUST be `final`
3. domain / client MUST NOT use `@Slf4j`
4. DTO / DO with `@Data @Builder` MUST also add `@NoArgsConstructor @AllArgsConstructor`

## Recommended

1. Service classes: `@RequiredArgsConstructor`, not `@Autowired`
2. ValueObject/Event: `@Getter @EqualsAndHashCode`, not `@Value`
3. `@ToString`: avoid including lazy-loaded / circular-reference fields