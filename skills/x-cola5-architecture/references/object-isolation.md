# Object Isolation

各层对象归属、跨层流转规则和转换规约。

## Object Types

| Type | Suffix | Layer | Purpose |
|------|--------|-------|---------|
| Command | `Cmd` | app | Write input |
| Query | `Qry` | app | Read input |
| View Object | `VO` | app | Frontend output |
| DTO | `DTO` | client | Service-to-service input/output |
| Entity | — | domain | Domain entity / aggregate root |
| Value Object | `V` | domain | Value object |
| Domain Event | `Event` | domain | Domain event |
| Data Object | `DO` | infrastructure | DB mapping |
| External Response | `Response` | infrastructure | External service response |

## Cross-layer Flow

| Type | adapter | app | domain | infrastructure |
|------|:-------:|:---:|:------:|:--------------:|
| Cmd/Qry/VO | use | define | — | — |
| DTO | use(client) | — | — | — |
| Entity/V/Event | — | use | define | use |
| DO/Response | — | — | — | define |

## Conversion

| Direction | Location | Method |
|-----------|----------|--------|
| Cmd → Entity | Cmd itself | `toEntity()` |
| Entity → VO | Qry/Cmd | `toVO()` |
| Entity ↔ DO | Converter / GatewayImpl | `toDO()` / `toEntity()` |
| Entity → DTO | ApiConverter (adapter.api) | `toDTO()` |
| Response → Entity | Client (infra) | `toEntity()` |

## Mandatory

1. Cmd/Qry/VO MUST be defined in app module
2. DTO MUST be defined in client module — MUST NOT leak to app/domain
3. DO MUST NOT leak to domain/app
4. External Response MUST NOT leak to domain
5. Conversion logic MUST NOT scatter in business code — extract to converter
6. MUST NOT pass non-owned objects across layers (e.g., Controller returning Entity)

## Recommended

1. Use MapStruct for Entity↔DO conversion
2. Simple conversion (1-2 fields) can be done directly in Cmd/GatewayImpl
3. DTO and VO may overlap but should be independent — different evolution pace
4. AggregateRoot provides `toVO()`/`toDTO()` to avoid getter exposing internal state