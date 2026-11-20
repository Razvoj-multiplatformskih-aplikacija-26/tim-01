FROM dart:3.14.0-sdk AS build
WORKDIR /workspace

COPY apps/server/pubspec.yaml apps/server/pubspec.yaml
COPY packages/domain/pubspec.yaml packages/domain/pubspec.yaml
COPY packages/api_contract/pubspec.yaml packages/api_contract/pubspec.yaml
COPY packages/api_mapping/pubspec.yaml packages/api_mapping/pubspec.yaml

# Use the server's Dart workspace members without the Flutter applications.
RUN printf '%s\n' \
    'name: device_guide_server_workspace' \
    'publish_to: none' \
    'environment:' \
    '  sdk: ^3.13.0' \
    'workspace:' \
    '  - apps/server' \
    '  - packages/domain' \
    '  - packages/api_contract' \
    '  - packages/api_mapping' > pubspec.yaml \
    && dart pub get

COPY apps/server/bin/ apps/server/bin/
COPY apps/server/lib/ apps/server/lib/
COPY packages/domain/lib/ packages/domain/lib/
COPY packages/api_contract/lib/ packages/api_contract/lib/
COPY packages/api_mapping/lib/ packages/api_mapping/lib/

RUN dart compile exe apps/server/bin/server.dart -o /workspace/device_guide_server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /workspace/device_guide_server /device_guide_server
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/device_guide_server"]
