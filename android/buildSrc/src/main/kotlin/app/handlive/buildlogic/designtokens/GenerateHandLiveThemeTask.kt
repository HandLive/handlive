package app.handlive.buildlogic.designtokens

import org.gradle.api.DefaultTask
import org.gradle.api.file.DirectoryProperty
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFile
import org.gradle.api.tasks.OutputDirectory
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

/**
 * Sinh `HandLiveColors`, `HandLiveTypography`, `HandLiveSpacing`/`Radius`/`Sizes`/`Durations` vào thư mục build.
 * Mã sinh ra không được commit: mỗi lần biên dịch đều sinh lại từ tokens.json, nên không thể lệch;
 * tokens.json sai (thiếu giao diện, bí danh hỏng, đơn vị lạ) thì task ném lỗi và build dừng.
 */
@CacheableTask
abstract class GenerateHandLiveThemeTask : DefaultTask() {
    @get:InputFile
    @get:PathSensitive(PathSensitivity.NONE)
    abstract val tokensFile: RegularFileProperty

    @get:Input
    abstract val packageName: Property<String>

    @get:OutputDirectory
    abstract val outputDirectory: DirectoryProperty

    @TaskAction
    fun generate() {
        val tokens = DesignTokensParser.parse(tokensFile.get().asFile)
        val packageDir = outputDirectory.get().asFile.resolve(packageName.get().replace('.', '/'))
        outputDirectory.get().asFile.deleteRecursively()
        packageDir.mkdirs()
        HandLiveThemeSourceWriter(packageName.get()).files(tokens).forEach { (fileName, source) ->
            packageDir.resolve(fileName).writeText(source)
        }
    }
}
